/* Backend Plan v2: collect-direct bookings and atomic seat claims.
   The existing demo seed uses events.status = 'open' and price_cents stores VND,
   so this migration keeps those columns as the compatibility boundary. */

ALTER TABLE profiles ADD COLUMN IF NOT EXISTS phone_verified boolean NOT NULL DEFAULT false;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS avatar_url text DEFAULT '';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS locale text NOT NULL DEFAULT 'vi' CHECK (locale IN ('vi', 'en'));
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS attended_count int NOT NULL DEFAULT 0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS no_show_count int NOT NULL DEFAULT 0;

CREATE OR REPLACE FUNCTION sync_phone_verification() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NEW.phone_confirmed_at IS NOT NULL THEN
    UPDATE profiles SET phone = COALESCE(NEW.phone, phone), phone_verified = true WHERE id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS on_auth_phone_confirmed ON auth.users;
CREATE TRIGGER on_auth_phone_confirmed AFTER UPDATE OF phone_confirmed_at ON auth.users
FOR EACH ROW WHEN (NEW.phone_confirmed_at IS NOT NULL) EXECUTE FUNCTION sync_phone_verification();

ALTER TABLE organizers ADD COLUMN IF NOT EXISTS owner_id uuid REFERENCES profiles(id) ON DELETE SET NULL;
ALTER TABLE organizers ADD COLUMN IF NOT EXISTS instagram text DEFAULT '';
ALTER TABLE organizers ADD COLUMN IF NOT EXISTS about text DEFAULT '';
ALTER TABLE organizers ADD COLUMN IF NOT EXISTS verify_requested_at timestamptz;
ALTER TABLE organizers ADD COLUMN IF NOT EXISTS pay_methods text[] NOT NULL DEFAULT '{}';
ALTER TABLE organizers ADD COLUMN IF NOT EXISTS bank_name text DEFAULT '';
ALTER TABLE organizers ADD COLUMN IF NOT EXISTS bank_account_name text DEFAULT '';
ALTER TABLE organizers ADD COLUMN IF NOT EXISTS bank_account_no text DEFAULT '';
ALTER TABLE organizers ADD COLUMN IF NOT EXISTS momo_phone text DEFAULT '';
ALTER TABLE organizers ADD COLUMN IF NOT EXISTS pay_qr_path text DEFAULT '';
ALTER TABLE organizers ADD COLUMN IF NOT EXISTS pay_note text DEFAULT '';
ALTER TABLE organizers ADD COLUMN IF NOT EXISTS refund_pledge text DEFAULT '';
ALTER TABLE organizers ADD COLUMN IF NOT EXISTS disputes_open int NOT NULL DEFAULT 0;

DROP POLICY IF EXISTS organizers_insert_owner ON organizers;
CREATE POLICY organizers_insert_owner ON organizers FOR INSERT TO authenticated WITH CHECK (
  auth.uid() = owner_id OR auth.uid() = user_id
);
DROP POLICY IF EXISTS organizers_update_owner ON organizers;
CREATE POLICY organizers_update_owner ON organizers FOR UPDATE TO authenticated USING (
  auth.uid() = owner_id OR auth.uid() = user_id
) WITH CHECK (auth.uid() = owner_id OR auth.uid() = user_id);
REVOKE SELECT ON organizers FROM anon, authenticated;
GRANT SELECT (id, name, ig_handle, instagram, bio, about, verified, hosting_since, event_count, created_at) ON organizers TO anon, authenticated;

ALTER TABLE events ADD COLUMN IF NOT EXISTS slug text;
ALTER TABLE events ADD COLUMN IF NOT EXISTS approval text NOT NULL DEFAULT 'host_approves' CHECK (approval IN ('instant', 'host_approves'));
ALTER TABLE events ADD COLUMN IF NOT EXISTS hold_minutes int NOT NULL DEFAULT 30;
ALTER TABLE events ADD COLUMN IF NOT EXISTS visibility text NOT NULL DEFAULT 'public' CHECK (visibility IN ('public', 'invite'));
ALTER TABLE events ADD COLUMN IF NOT EXISTS cancel_reason text DEFAULT '';
ALTER TABLE events ADD COLUMN IF NOT EXISTS cancelled_at timestamptz;
UPDATE events SET slug = key WHERE slug IS NULL;
ALTER TABLE events ALTER COLUMN slug SET NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_events_slug ON events(slug);

CREATE TABLE IF NOT EXISTS event_photos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  storage_path text NOT NULL,
  sort_order int NOT NULL DEFAULT 0
);
ALTER TABLE event_photos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS event_photos_select_public ON event_photos;
CREATE POLICY event_photos_select_public ON event_photos FOR SELECT TO anon, authenticated USING (
  EXISTS (SELECT 1 FROM events e WHERE e.id = event_id AND e.status IN ('open', 'sold_out', 'cancelled', 'ended'))
);

CREATE TABLE IF NOT EXISTS bookings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  qty int NOT NULL CHECK (qty > 0 AND qty <= 6),
  total_vnd bigint NOT NULL DEFAULT 0,
  code text NOT NULL UNIQUE,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'cancelled', 'expired', 'no_show', 'attended')),
  expires_at timestamptz,
  paid_marked_at timestamptz,
  paid_method text,
  paid_marked_by uuid REFERENCES profiles(id),
  cancelled_at timestamptz,
  cancelled_by uuid REFERENCES profiles(id),
  cancel_reason text,
  guest_note text,
  created_at timestamptz NOT NULL DEFAULT now(),
  confirmed_at timestamptz
);
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS bookings_select_participant ON bookings;
CREATE POLICY bookings_select_participant ON bookings FOR SELECT TO authenticated USING (
  user_id = auth.uid()
  OR EXISTS (SELECT 1 FROM events e JOIN organizers o ON o.id = e.organizer_id WHERE e.id = event_id AND (o.user_id = auth.uid() OR o.owner_id = auth.uid()))
  OR EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
);
DROP POLICY IF EXISTS bookings_update_participant ON bookings;
CREATE POLICY bookings_update_participant ON bookings FOR UPDATE TO authenticated USING (
  user_id = auth.uid()
  OR EXISTS (SELECT 1 FROM events e JOIN organizers o ON o.id = e.organizer_id WHERE e.id = event_id AND (o.user_id = auth.uid() OR o.owner_id = auth.uid()))
);
REVOKE INSERT ON bookings FROM anon, authenticated;

CREATE TABLE IF NOT EXISTS refund_claims (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id uuid NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  amount_vnd bigint NOT NULL,
  reason text NOT NULL CHECK (reason IN ('host_cancelled', 'guest_cancelled', 'dispute')),
  status text NOT NULL DEFAULT 'owed' CHECK (status IN ('owed', 'host_marked_sent', 'guest_confirmed', 'disputed', 'waived')),
  host_marked_at timestamptz,
  guest_confirmed_at timestamptz,
  note text
);
ALTER TABLE refund_claims ENABLE ROW LEVEL SECURITY;
CREATE POLICY refund_claims_select_participant ON refund_claims FOR SELECT TO authenticated USING (
  EXISTS (SELECT 1 FROM bookings b WHERE b.id = booking_id AND b.user_id = auth.uid())
  OR EXISTS (SELECT 1 FROM bookings b JOIN events e ON e.id = b.event_id JOIN organizers o ON o.id = e.organizer_id WHERE b.id = booking_id AND (o.user_id = auth.uid() OR o.owner_id = auth.uid()))
);

CREATE TABLE IF NOT EXISTS threads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  guest_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  organizer_id uuid NOT NULL REFERENCES organizers(id) ON DELETE CASCADE,
  UNIQUE(event_id, guest_id)
);
ALTER TABLE threads ENABLE ROW LEVEL SECURITY;
CREATE POLICY threads_select_participant ON threads FOR SELECT TO authenticated USING (
  guest_id = auth.uid() OR EXISTS (SELECT 1 FROM organizers o WHERE o.id = organizer_id AND (o.user_id = auth.uid() OR o.owner_id = auth.uid()))
);
CREATE TABLE IF NOT EXISTS thread_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  thread_id uuid NOT NULL REFERENCES threads(id) ON DELETE CASCADE,
  sender_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  body text NOT NULL,
  kind text NOT NULL DEFAULT 'text' CHECK (kind IN ('text', 'system')),
  created_at timestamptz NOT NULL DEFAULT now(),
  read_at timestamptz
);
ALTER TABLE thread_messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY thread_messages_select_participant ON thread_messages FOR SELECT TO authenticated USING (
  EXISTS (SELECT 1 FROM threads t WHERE t.id = thread_id AND (t.guest_id = auth.uid() OR EXISTS (SELECT 1 FROM organizers o WHERE o.id = t.organizer_id AND (o.user_id = auth.uid() OR o.owner_id = auth.uid()))))
);
CREATE POLICY thread_messages_insert_participant ON thread_messages FOR INSERT TO authenticated WITH CHECK (
  sender_id = auth.uid() AND EXISTS (SELECT 1 FROM threads t WHERE t.id = thread_id AND (t.guest_id = auth.uid() OR EXISTS (SELECT 1 FROM organizers o WHERE o.id = t.organizer_id AND (o.user_id = auth.uid() OR o.owner_id = auth.uid()))))
);

CREATE OR REPLACE VIEW v_event_availability AS
SELECT e.id, e.slug, e.capacity,
  COALESCE(SUM(CASE WHEN b.status IN ('confirmed', 'attended') OR (b.status = 'pending' AND b.expires_at > now()) THEN b.qty ELSE 0 END), 0)::int AS live_claims,
  GREATEST(e.capacity - COALESCE(SUM(CASE WHEN b.status IN ('confirmed', 'attended') OR (b.status = 'pending' AND b.expires_at > now()) THEN b.qty ELSE 0 END), 0), 0)::int AS seats_left
FROM events e LEFT JOIN bookings b ON b.event_id = e.id GROUP BY e.id;

CREATE INDEX IF NOT EXISTS idx_bookings_event_status ON bookings(event_id, status);
CREATE INDEX IF NOT EXISTS idx_bookings_user ON bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_code ON bookings(code);
CREATE INDEX IF NOT EXISTS idx_events_status_date ON events(status, event_date);
CREATE INDEX IF NOT EXISTS idx_thread_messages_thread_created ON thread_messages(thread_id, created_at);

CREATE OR REPLACE FUNCTION claim_seats(p_event uuid, p_qty int, p_note text DEFAULT NULL)
RETURNS bookings LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_event events%ROWTYPE; v_taken int; v_booking bookings%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'AUTH_REQUIRED'; END IF;
  IF p_qty IS NULL OR p_qty < 1 OR p_qty > 6 THEN RAISE EXCEPTION 'INVALID_QTY'; END IF;
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND phone_verified) THEN RAISE EXCEPTION 'PHONE_REQUIRED'; END IF;
  SELECT * INTO v_event FROM events WHERE id = p_event FOR UPDATE;
  IF NOT FOUND OR v_event.status <> 'open' THEN RAISE EXCEPTION 'NOT_LIVE'; END IF;
  IF EXISTS (SELECT 1 FROM bookings WHERE event_id = p_event AND user_id = auth.uid() AND status = 'pending' AND expires_at > now()) THEN RAISE EXCEPTION 'PENDING_EXISTS'; END IF;
  SELECT COALESCE(SUM(qty), 0) INTO v_taken FROM bookings WHERE event_id = p_event AND (status IN ('confirmed', 'attended') OR (status = 'pending' AND expires_at > now()));
  IF v_taken + p_qty > v_event.capacity THEN RAISE EXCEPTION 'SOLD_OUT'; END IF;
  INSERT INTO bookings(event_id, user_id, qty, total_vnd, code, guest_note, status, expires_at, confirmed_at)
  VALUES (p_event, auth.uid(), p_qty, p_qty * (v_event.price_cents / 100),
    upper(substr(md5(gen_random_uuid()::text), 1, 6)), p_note,
    CASE WHEN v_event.approval = 'instant' THEN 'confirmed' ELSE 'pending' END,
    CASE WHEN v_event.approval = 'instant' THEN NULL ELSE now() + make_interval(mins => v_event.hold_minutes) END,
    CASE WHEN v_event.approval = 'instant' THEN now() ELSE NULL END)
  RETURNING * INTO v_booking;
  INSERT INTO threads(event_id, guest_id, organizer_id) VALUES (p_event, auth.uid(), v_event.organizer_id) ON CONFLICT DO NOTHING;
  RETURN v_booking;
END;
$$;
REVOKE EXECUTE ON FUNCTION claim_seats(uuid, int, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION claim_seats(uuid, int, text) TO authenticated;

CREATE OR REPLACE FUNCTION expire_bookings() RETURNS int LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_count int;
BEGIN
  UPDATE bookings SET status = 'expired' WHERE status = 'pending' AND expires_at <= now();
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;
REVOKE EXECUTE ON FUNCTION expire_bookings() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION expire_bookings() TO authenticated;

CREATE OR REPLACE FUNCTION enforce_booking_transition() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF OLD.status = NEW.status THEN RETURN NEW; END IF;
  IF NOT ((OLD.status = 'pending' AND NEW.status IN ('confirmed', 'cancelled', 'expired'))
    OR (OLD.status = 'confirmed' AND NEW.status IN ('attended', 'no_show', 'cancelled')))
  THEN RAISE EXCEPTION 'ILLEGAL_BOOKING_TRANSITION'; END IF;
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS booking_status_transition ON bookings;
CREATE TRIGGER booking_status_transition BEFORE UPDATE OF status ON bookings
FOR EACH ROW EXECUTE FUNCTION enforce_booking_transition();

CREATE OR REPLACE FUNCTION confirm_payment(p_booking uuid, p_method text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM bookings b JOIN events e ON e.id = b.event_id JOIN organizers o ON o.id = e.organizer_id WHERE b.id = p_booking AND (o.user_id = auth.uid() OR o.owner_id = auth.uid())) THEN
    RETURN jsonb_build_object('success', false, 'error', 'NOT_AUTHORIZED');
  END IF;
  UPDATE bookings SET status = 'confirmed', paid_marked_at = now(), paid_method = p_method, paid_marked_by = auth.uid(), confirmed_at = now()
  WHERE id = p_booking AND status = 'pending' AND (expires_at IS NULL OR expires_at > now());
  IF NOT FOUND THEN RETURN jsonb_build_object('success', false, 'error', 'BOOKING_NOT_PENDING'); END IF;
  RETURN jsonb_build_object('success', true);
END;
$$;
REVOKE EXECUTE ON FUNCTION confirm_payment(uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION confirm_payment(uuid, text) TO authenticated;

CREATE OR REPLACE FUNCTION cancel_event(p_event uuid, p_reason text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_booking bookings%ROWTYPE;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM events e JOIN organizers o ON o.id = e.organizer_id WHERE e.id = p_event AND (o.user_id = auth.uid() OR o.owner_id = auth.uid())) THEN
    RETURN jsonb_build_object('success', false, 'error', 'NOT_AUTHORIZED');
  END IF;
  UPDATE events SET status = 'cancelled', cancelled_at = now(), cancel_reason = p_reason WHERE id = p_event;
  FOR v_booking IN SELECT * FROM bookings WHERE event_id = p_event AND status IN ('pending', 'confirmed') LOOP
    UPDATE bookings SET status = 'cancelled', cancelled_at = now(), cancelled_by = auth.uid(), cancel_reason = p_reason WHERE id = v_booking.id;
    IF v_booking.status = 'confirmed' THEN INSERT INTO refund_claims(booking_id, amount_vnd, reason) VALUES (v_booking.id, v_booking.total_vnd, 'host_cancelled'); END IF;
  END LOOP;
  RETURN jsonb_build_object('success', true);
END;
$$;
REVOKE EXECUTE ON FUNCTION cancel_event(uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION cancel_event(uuid, text) TO authenticated;

CREATE OR REPLACE FUNCTION check_in(p_code text, p_no_show boolean DEFAULT false)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_booking bookings%ROWTYPE;
BEGIN
  SELECT b.* INTO v_booking FROM bookings b JOIN events e ON e.id = b.event_id JOIN organizers o ON o.id = e.organizer_id WHERE b.code = upper(p_code) AND (o.user_id = auth.uid() OR o.owner_id = auth.uid());
  IF NOT FOUND OR v_booking.status <> 'confirmed' THEN RETURN jsonb_build_object('success', false, 'error', 'BOOKING_NOT_CHECKABLE'); END IF;
  UPDATE bookings SET status = CASE WHEN p_no_show THEN 'no_show' ELSE 'attended' END WHERE id = v_booking.id;
  UPDATE profiles SET no_show_count = no_show_count + 1 WHERE id = v_booking.user_id AND p_no_show;
  UPDATE profiles SET attended_count = attended_count + 1 WHERE id = v_booking.user_id AND NOT p_no_show;
  RETURN jsonb_build_object('success', true, 'booking_id', v_booking.id, 'status', CASE WHEN p_no_show THEN 'no_show' ELSE 'attended' END);
END;
$$;
REVOKE EXECUTE ON FUNCTION check_in(text, boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION check_in(text, boolean) TO authenticated;

CREATE OR REPLACE FUNCTION create_event_draft(
  p_name text, p_category text, p_description text, p_location text,
  p_event_date date, p_event_time time, p_price_vnd bigint, p_capacity int,
  p_organizer_name text, p_instagram text DEFAULT '', p_about text DEFAULT ''
) RETURNS events LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_organizer organizers%ROWTYPE; v_event events%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'AUTH_REQUIRED'; END IF;
  IF p_name IS NULL OR length(trim(p_name)) = 0 OR p_capacity IS NULL OR p_capacity < 1 THEN RAISE EXCEPTION 'INVALID_EVENT'; END IF;
  UPDATE profiles SET role = CASE WHEN role = 'goer' THEN 'host' ELSE role END WHERE id = auth.uid();
  SELECT * INTO v_organizer FROM organizers WHERE owner_id = auth.uid() OR user_id = auth.uid() ORDER BY created_at LIMIT 1;
  IF NOT FOUND THEN
    INSERT INTO organizers(owner_id, user_id, name, ig_handle, instagram, bio, about)
    VALUES (auth.uid(), auth.uid(), COALESCE(NULLIF(trim(p_organizer_name), ''), 'Organizer'), p_instagram, p_instagram, p_about, p_about)
    RETURNING * INTO v_organizer;
  ELSE
    UPDATE organizers SET name = COALESCE(NULLIF(trim(p_organizer_name), ''), name), instagram = COALESCE(p_instagram, instagram), about = COALESCE(p_about, about) WHERE id = v_organizer.id;
  END IF;
  INSERT INTO events(key, slug, organizer_id, name, cat_key, cat_label, description, price_text, price_cents, is_free, capacity, seats_remaining, location, area, event_date, event_time, status, approval, visibility)
  VALUES (lower(regexp_replace(trim(p_name), '[^a-zA-Z0-9]+', '-', 'g')) || '-' || substr(md5(gen_random_uuid()::text), 1, 6),
    lower(regexp_replace(trim(p_name), '[^a-zA-Z0-9]+', '-', 'g')) || '-' || substr(md5(gen_random_uuid()::text), 1, 6),
    v_organizer.id, trim(p_name), p_category, p_category, COALESCE(p_description, ''),
    CASE WHEN COALESCE(p_price_vnd, 0) = 0 THEN 'Miễn phí' ELSE to_char(p_price_vnd, 'FM999G999G999') || '₫' END,
    COALESCE(p_price_vnd, 0) * 100, COALESCE(p_price_vnd, 0) = 0, p_capacity, p_capacity,
    COALESCE(p_location, ''), COALESCE(p_location, ''), p_event_date, p_event_time, 'pending', 'host_approves', 'public')
  RETURNING * INTO v_event;
  RETURN v_event;
END;
$$;
REVOKE EXECUTE ON FUNCTION create_event_draft(text, text, text, text, date, time, bigint, int, text, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION create_event_draft(text, text, text, text, date, time, bigint, int, text, text, text) TO authenticated;

CREATE OR REPLACE FUNCTION approve_event(p_event_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin') THEN
    RETURN jsonb_build_object('success', false, 'error', 'NOT_AUTHORIZED');
  END IF;
  UPDATE events SET status = CASE WHEN seats_remaining = 0 THEN 'sold_out' ELSE 'open' END WHERE id = p_event_id AND status = 'pending';
  IF NOT FOUND THEN RETURN jsonb_build_object('success', false, 'error', 'EVENT_NOT_PENDING'); END IF;
  RETURN jsonb_build_object('success', true);
END;
$$;
REVOKE EXECUTE ON FUNCTION approve_event(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION approve_event(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION get_organizer_payout_details(p_organizer uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM organizers o WHERE o.id = p_organizer AND (o.owner_id = auth.uid() OR o.user_id = auth.uid())
  ) AND NOT EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
  ) AND NOT EXISTS (
    SELECT 1 FROM bookings b JOIN events e ON e.id = b.event_id
    WHERE e.organizer_id = p_organizer AND b.user_id = auth.uid() AND b.status IN ('pending', 'confirmed', 'attended')
  ) THEN
    RETURN jsonb_build_object('success', false, 'error', 'NOT_AUTHORIZED');
  END IF;
  RETURN (SELECT jsonb_build_object(
    'pay_methods', pay_methods, 'bank_name', bank_name,
    'bank_account_name', bank_account_name, 'bank_account_no', bank_account_no,
    'momo_phone', momo_phone, 'pay_qr_path', pay_qr_path,
    'pay_note', pay_note, 'refund_pledge', refund_pledge
  ) FROM organizers WHERE id = p_organizer);
END;
$$;
REVOKE EXECUTE ON FUNCTION get_organizer_payout_details(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION get_organizer_payout_details(uuid) TO authenticated;