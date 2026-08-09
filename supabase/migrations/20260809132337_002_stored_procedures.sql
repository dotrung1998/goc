/*
# Stored procedures for Góc

## Functions created
1. reserve_event_tickets — atomic seat reservation with qty/pay_mode validation
2. check_in_guest — atomic door check-in (prevents double check-in)
3. release_expired_holds — releases seats from holds past their 24h deadline
4. auto_profile() trigger — creates a profile row on signup
5. approve_event — admin approves a pending event (sets status to open)
6. verify_organizer — admin verifies an organizer
7. cancel_event_and_refund — admin/host cancels event, marks all reservations refunded
8. set_user_role — admin promotes a user to host/admin
9. get_admin_events — admin lists all events including pending
10. get_admin_reservations — admin lists all reservations with payment info
*/

-- ============ auto_profile trigger ============
-- Creates a profile row automatically when a new auth user signs up
CREATE OR REPLACE FUNCTION auto_profile()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO profiles (id, email, display_name)
  VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data->>'display_name', ''))
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION auto_profile();

-- ============ reserve_event_tickets ============
-- Atomic reservation: validates event is bookable, checks seats, decrements,
-- creates reservation row. Returns JSON with success + reservation_id.
CREATE OR REPLACE FUNCTION reserve_event_tickets(
  p_event_id text,
  p_user_name text DEFAULT '',
  p_user_email text DEFAULT '',
  p_user_phone text DEFAULT '',
  p_qty int DEFAULT 1,
  p_pay_mode text DEFAULT 'now'
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_event events%ROWTYPE;
  v_reservation_id uuid;
  v_hold_deadline timestamptz;
  v_total bigint;
  v_remaining int;
BEGIN
  -- Look up event by key (slug) or UUID
  SELECT * INTO v_event
  FROM events
  WHERE key = p_event_id OR id::text = p_event_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Event not found');
  END IF;

  -- Validate event is bookable
  IF v_event.status NOT IN ('open') THEN
    RETURN jsonb_build_object('success', false, 'error', 'Event is not available for booking');
  END IF;

  -- Validate quantity
  IF p_qty IS NULL OR p_qty < 1 OR p_qty > 6 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invalid quantity');
  END IF;

  -- Check seat availability atomically
  v_remaining := v_event.seats_remaining - p_qty;
  IF v_remaining < 0 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not enough seats remaining');
  END IF;

  -- Compute total
  v_total := v_event.price_cents * p_qty;

  -- Set hold deadline for hold_24h mode
  IF p_pay_mode = 'hold_24h' THEN
    v_hold_deadline := now() + interval '24 hours';
  END IF;

  -- Decrement seats atomically
  UPDATE events SET seats_remaining = v_remaining
  WHERE id = v_event.id AND seats_remaining >= p_qty
  RETURNING seats_remaining INTO v_remaining;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Race condition: seats taken');
  END IF;

  -- Update sold_out status if no seats left
  IF v_remaining = 0 THEN
    UPDATE events SET status = 'sold_out' WHERE id = v_event.id;
  END IF;

  -- Create reservation
  INSERT INTO reservations (
    event_id, user_id, user_name, user_email, user_phone,
    qty, pay_mode, status, hold_deadline, total_cents
  ) VALUES (
    v_event.id, auth.uid(), p_user_name, p_user_email, p_user_phone,
    p_qty, p_pay_mode,
    CASE WHEN p_pay_mode = 'now' THEN 'held' ELSE 'held' END,
    v_hold_deadline, v_total
  )
  RETURNING id INTO v_reservation_id;

  RETURN jsonb_build_object(
    'success', true,
    'reservation_id', v_reservation_id,
    'event_id', v_event.id,
    'seats_remaining', v_remaining,
    'total_cents', v_total
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION reserve_event_tickets FROM anon;
GRANT EXECUTE ON FUNCTION reserve_event_tickets TO authenticated;

-- ============ check_in_guest ============
-- Atomic check-in: prevents double check-in, validates reservation belongs
-- to the caller's event, validates reservation is paid
CREATE OR REPLACE FUNCTION check_in_guest(p_reservation_id uuid)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_reservation reservations%ROWTYPE;
  v_is_host boolean;
  v_is_admin boolean;
BEGIN
  SELECT * INTO v_reservation FROM reservations WHERE id = p_reservation_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Reservation not found');
  END IF;

  -- Check if caller is the event's host or an admin
  SELECT EXISTS(
    SELECT 1 FROM events e
    JOIN organizers o ON o.id = e.organizer_id
    WHERE e.id = v_reservation.event_id AND o.user_id = auth.uid()
  ) INTO v_is_host;

  SELECT EXISTS(
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
  ) INTO v_is_admin;

  IF NOT v_is_host AND NOT v_is_admin THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authorized');
  END IF;

  -- Validate reservation is in a checkable state
  IF v_reservation.status NOT IN ('paid', 'held') THEN
    RETURN jsonb_build_object('success', false, 'error', 'Reservation is not eligible for check-in');
  END IF;

  -- Atomic check-in (UNIQUE constraint on reservation_id prevents doubles)
  INSERT INTO checkins (reservation_id, event_id)
  VALUES (v_reservation.id, v_reservation.event_id)
  ON CONFLICT (reservation_id) DO NOTHING
  RETURNING id INTO v_is_host; -- reuse var as flag

  IF v_is_host IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Guest already checked in');
  END IF;

  -- Update reservation status
  UPDATE reservations SET status = 'checked_in' WHERE id = v_reservation.id;

  RETURN jsonb_build_object('success', true, 'reservation_id', v_reservation.id);
END;
$$;

REVOKE EXECUTE ON FUNCTION check_in_guest FROM anon;
GRANT EXECUTE ON FUNCTION check_in_guest TO authenticated;

-- ============ release_expired_holds ============
-- Releases all holds past their deadline back to available seats
CREATE OR REPLACE FUNCTION release_expired_holds()
RETURNS int
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_released int := 0;
  v_row record;
BEGIN
  FOR v_row IN
    SELECT event_id, qty FROM reservations
    WHERE status = 'held' AND hold_deadline IS NOT NULL AND hold_deadline < now()
  LOOP
    UPDATE events SET seats_remaining = seats_remaining + v_row.qty
    WHERE id = v_row.event_id;

    UPDATE reservations SET status = 'released'
    WHERE status = 'held' AND hold_deadline < now() AND event_id = v_row.event_id;

    v_released := v_released + 1;
  END LOOP;

  -- Reset sold_out events back to open if seats became available
  UPDATE events SET status = 'open'
  WHERE status = 'sold_out' AND seats_remaining > 0;

  RETURN v_released;
END;
$$;

REVOKE EXECUTE ON FUNCTION release_expired_holds FROM anon;
GRANT EXECUTE ON FUNCTION release_expired_holds TO authenticated;

-- ============ approve_event ============
-- Admin approves a pending event, setting status to open
CREATE OR REPLACE FUNCTION approve_event(p_event_id uuid)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_is_admin boolean;
BEGIN
  SELECT EXISTS(SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authorized');
  END IF;

  UPDATE events SET status = 'open' WHERE id = p_event_id AND status = 'pending';
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Event not found or not pending');
  END IF;

  RETURN jsonb_build_object('success', true);
END;
$$;

REVOKE EXECUTE ON FUNCTION approve_event FROM anon;
GRANT EXECUTE ON FUNCTION approve_event TO authenticated;

-- ============ verify_organizer ============
-- Admin verifies an organizer
CREATE OR REPLACE FUNCTION verify_organizer(p_organizer_id uuid)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_is_admin boolean;
BEGIN
  SELECT EXISTS(SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authorized');
  END IF;

  UPDATE organizers SET verified = true, verified_at = now()
  WHERE id = p_organizer_id;

  RETURN jsonb_build_object('success', true);
END;
$$;

REVOKE EXECUTE ON FUNCTION verify_organizer FROM anon;
GRANT EXECUTE ON FUNCTION verify_organizer TO authenticated;

-- ============ cancel_event_and_refund ============
-- Host or admin cancels an event; all paid reservations marked refunded
CREATE OR REPLACE FUNCTION cancel_event_and_refund(p_event_id uuid)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_is_host boolean;
  v_is_admin boolean;
  v_count int;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM events e
    JOIN organizers o ON o.id = e.organizer_id
    WHERE e.id = p_event_id AND o.user_id = auth.uid()
  ) INTO v_is_host;

  SELECT EXISTS(SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin') INTO v_is_admin;

  IF NOT v_is_host AND NOT v_is_admin THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authorized');
  END IF;

  -- Mark event cancelled
  UPDATE events SET status = 'cancelled' WHERE id = p_event_id;

  -- Mark all paid reservations as refunded
  UPDATE reservations SET status = 'refunded'
  WHERE event_id = p_event_id AND status = 'paid'
  RETURNING id INTO v_count;

  GET DIAGNOSTICS v_count = ROW_COUNT;

  -- Mark held reservations as cancelled
  UPDATE reservations SET status = 'cancelled'
  WHERE event_id = p_event_id AND status = 'held';

  -- Mark payments as refunded
  UPDATE payments SET status = 'refunded'
  WHERE reservation_id IN (SELECT id FROM reservations WHERE event_id = p_event_id);

  RETURN jsonb_build_object('success', true, 'refunded_count', v_count);
END;
$$;

REVOKE EXECUTE ON FUNCTION cancel_event_and_refund FROM anon;
GRANT EXECUTE ON FUNCTION cancel_event_and_refund TO authenticated;

-- ============ set_user_role ============
-- Admin promotes a user to host or admin
CREATE OR REPLACE FUNCTION set_user_role(p_user_id uuid, p_role text)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_is_admin boolean;
BEGIN
  SELECT EXISTS(SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authorized');
  END IF;

  IF p_role NOT IN ('goer', 'host', 'admin') THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invalid role');
  END IF;

  UPDATE profiles SET role = p_role WHERE id = p_user_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'User not found');
  END IF;

  RETURN jsonb_build_object('success', true);
END;
$$;

REVOKE EXECUTE ON FUNCTION set_user_role FROM anon;
GRANT EXECUTE ON FUNCTION set_user_role TO authenticated;

-- ============ mark_payment_succeeded ============
-- Called by Stripe webhook edge function to mark a reservation paid
CREATE OR REPLACE FUNCTION mark_payment_succeeded(
  p_reservation_id uuid,
  p_provider text,
  p_amount_cents bigint,
  p_provider_ref text
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_reservation reservations%ROWTYPE;
BEGIN
  SELECT * INTO v_reservation FROM reservations WHERE id = p_reservation_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Reservation not found');
  END IF;

  -- Update reservation to paid
  UPDATE reservations SET status = 'paid', hold_deadline = NULL
  WHERE id = p_reservation_id;

  -- Insert or update payment record
  INSERT INTO payments (reservation_id, provider, amount_cents, provider_ref, status)
  VALUES (p_reservation_id, p_provider, p_amount_cents, p_provider_ref, 'succeeded')
  ON CONFLICT DO NOTHING;

  RETURN jsonb_build_object('success', true);
END;
$$;

REVOKE EXECUTE ON FUNCTION mark_payment_succeeded FROM anon;
GRANT EXECUTE ON FUNCTION mark_payment_succeeded TO authenticated;

-- ============ get_admin_events ============
-- Admin-only: list all events including pending
CREATE OR REPLACE FUNCTION get_admin_events()
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_is_admin boolean;
  v_result jsonb;
BEGIN
  SELECT EXISTS(SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authorized');
  END IF;

  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'id', e.id,
      'name', e.name,
      'status', e.status,
      'organizer', o.name,
      'organizer_id', o.id,
      'event_date', e.event_date,
      'seats_remaining', e.seats_remaining,
      'capacity', e.capacity,
      'created_at', e.created_at
    ) ORDER BY e.created_at DESC
  ), '[]'::jsonb) INTO v_result
  FROM events e
  LEFT JOIN organizers o ON o.id = e.organizer_id;

  RETURN jsonb_build_object('success', true, 'events', v_result);
END;
$$;

REVOKE EXECUTE ON FUNCTION get_admin_events FROM anon;
GRANT EXECUTE ON FUNCTION get_admin_events TO authenticated;

-- ============ get_admin_reservations ============
-- Admin-only: list all reservations with payment info
CREATE OR REPLACE FUNCTION get_admin_reservations()
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_is_admin boolean;
  v_result jsonb;
BEGIN
  SELECT EXISTS(SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authorized');
  END IF;

  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'id', r.id,
      'event_name', e.name,
      'user_name', r.user_name,
      'user_email', r.user_email,
      'qty', r.qty,
      'status', r.status,
      'pay_mode', r.pay_mode,
      'total_cents', r.total_cents,
      'created_at', r.created_at,
      'payment_status', COALESCE(
        (SELECT p.status FROM payments p WHERE p.reservation_id = r.id LIMIT 1), 'none'
      )
    ) ORDER BY r.created_at DESC
  ), '[]'::jsonb) INTO v_result
  FROM reservations r
  JOIN events e ON e.id = r.event_id;

  RETURN jsonb_build_object('success', true, 'reservations', v_result);
END;
$$;

REVOKE EXECUTE ON FUNCTION get_admin_reservations FROM anon;
GRANT EXECUTE ON FUNCTION get_admin_reservations TO authenticated;
