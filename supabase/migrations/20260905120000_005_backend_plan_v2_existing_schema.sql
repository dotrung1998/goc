/*
  Backend Plan v2 compatibility migration for the existing banbe database.

  The existing database uses text event/organizer IDs and exposes public CRUD
  policies on reservations and chats. This migration keeps those IDs, closes
  those policies, and adds the v2 collect-direct lifecycle around them.
*/

CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
BEGIN
  BEGIN
    EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE public.reservations, public.chats, public.banbe_messages';
  EXCEPTION WHEN duplicate_object OR undefined_object THEN NULL;
  END;
END;
$$;

DROP POLICY IF EXISTS banbe_event_photos_read ON storage.objects;
CREATE POLICY banbe_event_photos_read ON storage.objects FOR SELECT TO anon, authenticated USING (bucket_id = 'event-photos');
DROP POLICY IF EXISTS banbe_event_photos_owner_write ON storage.objects;
CREATE POLICY banbe_event_photos_owner_write ON storage.objects FOR INSERT TO authenticated WITH CHECK (
  bucket_id = 'event-photos' AND EXISTS (SELECT 1 FROM organizers o WHERE o.owner_id = auth.uid() AND (storage.foldername(name))[1] = o.id)
);
DROP POLICY IF EXISTS banbe_pay_qr_owner_read ON storage.objects;
CREATE POLICY banbe_pay_qr_owner_read ON storage.objects FOR SELECT TO authenticated USING (
  bucket_id = 'pay-qr' AND (
    EXISTS (SELECT 1 FROM organizers o WHERE o.owner_id = auth.uid() AND (storage.foldername(name))[1] = o.id)
    OR EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
    OR EXISTS (SELECT 1 FROM reservations r JOIN events e ON e.id = r.event_id JOIN organizers o ON o.id = e.organizer_id WHERE r.user_id = auth.uid() AND (storage.foldername(name))[1] = o.id AND r.status IN ('pending', 'held', 'confirmed', 'paid', 'checked_in'))
  )
);

CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL DEFAULT '',
  display_name text NOT NULL DEFAULT '',
  phone text DEFAULT '',
  phone_verified boolean NOT NULL DEFAULT false,
  role text NOT NULL DEFAULT 'participant' CHECK (role IN ('participant', 'organizer', 'admin')),
  attended_count int NOT NULL DEFAULT 0,
  no_show_count int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS profiles_self_read ON profiles;
CREATE POLICY profiles_self_read ON profiles FOR SELECT TO authenticated USING (id = auth.uid());
DROP POLICY IF EXISTS profiles_self_update ON profiles;
CREATE POLICY profiles_self_update ON profiles FOR UPDATE TO authenticated USING (id = auth.uid()) WITH CHECK (id = auth.uid());
REVOKE UPDATE ON profiles FROM authenticated;
GRANT UPDATE (display_name, phone) ON profiles TO authenticated;

CREATE OR REPLACE FUNCTION banbe_auto_profile() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO profiles(id, email, display_name, phone, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.email, ''),
    COALESCE(NEW.raw_user_meta_data->>'display_name', ''),
    COALESCE(NEW.phone, ''),
    CASE WHEN NEW.raw_user_meta_data->>'account_type' = 'organizer' THEN 'organizer' ELSE 'participant' END
  )
  ON CONFLICT (id) DO UPDATE SET email = EXCLUDED.email, phone = EXCLUDED.phone;
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS banbe_auth_user_created ON auth.users;
CREATE TRIGGER banbe_auth_user_created AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION banbe_auto_profile();

ALTER TABLE organizers ADD COLUMN IF NOT EXISTS owner_id uuid REFERENCES profiles(id) ON DELETE SET NULL;
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
ALTER TABLE organizers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public organizers read" ON organizers;
DROP POLICY IF EXISTS organizers_public_read ON organizers;
CREATE POLICY organizers_public_read ON organizers FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS organizers_owner_insert ON organizers;
CREATE POLICY organizers_owner_insert ON organizers FOR INSERT TO authenticated WITH CHECK (owner_id = auth.uid());
DROP POLICY IF EXISTS organizers_owner_update ON organizers;
CREATE POLICY organizers_owner_update ON organizers FOR UPDATE TO authenticated USING (owner_id = auth.uid()) WITH CHECK (owner_id = auth.uid());
REVOKE SELECT ON organizers FROM anon, authenticated;
GRANT SELECT (id, name, ig, description, since_year, event_count, is_trusted, created_at) ON organizers TO anon, authenticated;

ALTER TABLE events ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'live' CHECK (status IN ('draft', 'review', 'live', 'cancelled', 'ended'));
ALTER TABLE events ADD COLUMN IF NOT EXISTS approval text NOT NULL DEFAULT 'host_approves' CHECK (approval IN ('instant', 'host_approves'));
ALTER TABLE events ADD COLUMN IF NOT EXISTS hold_minutes int NOT NULL DEFAULT 30;
ALTER TABLE events ADD COLUMN IF NOT EXISTS visibility text NOT NULL DEFAULT 'public' CHECK (visibility IN ('public', 'invite'));
ALTER TABLE events ADD COLUMN IF NOT EXISTS cancel_reason text DEFAULT '';
ALTER TABLE events ADD COLUMN IF NOT EXISTS cancelled_at timestamptz;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public events read" ON events;
DROP POLICY IF EXISTS events_public_read ON events;
CREATE POLICY events_public_read ON events FOR SELECT TO anon, authenticated USING (
  status IN ('live', 'cancelled', 'ended')
  OR EXISTS (SELECT 1 FROM organizers o WHERE o.id = events.organizer_id AND o.owner_id = auth.uid())
  OR EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
);
DROP POLICY IF EXISTS events_owner_update ON events;
CREATE POLICY events_owner_update ON events FOR UPDATE TO authenticated USING (
  EXISTS (SELECT 1 FROM organizers o WHERE o.id = organizer_id AND o.owner_id = auth.uid())
  OR EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
);

CREATE TABLE IF NOT EXISTS event_photos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id text NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  storage_path text NOT NULL,
  sort_order int NOT NULL DEFAULT 0
);
ALTER TABLE event_photos ENABLE ROW LEVEL SECURITY;
CREATE POLICY event_photos_public_read ON event_photos FOR SELECT TO anon, authenticated USING (
  EXISTS (SELECT 1 FROM events e WHERE e.id = event_id AND e.status IN ('live', 'cancelled', 'ended'))
);
CREATE POLICY event_photos_owner_insert ON event_photos FOR INSERT TO authenticated WITH CHECK (
  EXISTS (SELECT 1 FROM events e JOIN organizers o ON o.id = e.organizer_id WHERE e.id = event_id AND o.owner_id = auth.uid())
);

ALTER TABLE reservations ADD COLUMN IF NOT EXISTS code text;
ALTER TABLE reservations ADD COLUMN IF NOT EXISTS total_vnd bigint NOT NULL DEFAULT 0;
ALTER TABLE reservations ADD COLUMN IF NOT EXISTS expires_at timestamptz;
ALTER TABLE reservations ADD COLUMN IF NOT EXISTS paid_marked_at timestamptz;
ALTER TABLE reservations ADD COLUMN IF NOT EXISTS paid_method text;
ALTER TABLE reservations ADD COLUMN IF NOT EXISTS paid_marked_by uuid REFERENCES profiles(id);
ALTER TABLE reservations ADD COLUMN IF NOT EXISTS cancelled_at timestamptz;
ALTER TABLE reservations ADD COLUMN IF NOT EXISTS cancelled_by uuid REFERENCES profiles(id);
ALTER TABLE reservations ADD COLUMN IF NOT EXISTS cancel_reason text;
ALTER TABLE reservations ADD COLUMN IF NOT EXISTS guest_note text;
ALTER TABLE reservations ADD COLUMN IF NOT EXISTS confirmed_at timestamptz;
UPDATE reservations SET code = upper(substr(md5(id::text), 1, 6)) WHERE code IS NULL;
ALTER TABLE reservations ALTER COLUMN code SET NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS reservations_code_unique ON reservations(code);
ALTER TABLE reservations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public reservations update" ON reservations;
DROP POLICY IF EXISTS "Public reservations insert" ON reservations;
DROP POLICY IF EXISTS "Public reservations read" ON reservations;
DROP POLICY IF EXISTS reservations_participant_read ON reservations;
CREATE POLICY reservations_participant_read ON reservations FOR SELECT TO authenticated USING (
  user_id = auth.uid()
  OR EXISTS (SELECT 1 FROM events e JOIN organizers o ON o.id = e.organizer_id WHERE e.id = reservations.event_id AND o.owner_id = auth.uid())
  OR EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
);
REVOKE INSERT, UPDATE, DELETE ON reservations FROM anon, authenticated;
GRANT UPDATE (user_name, user_email, user_phone) ON reservations TO authenticated;

CREATE TABLE IF NOT EXISTS refund_claims (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reservation_id uuid NOT NULL REFERENCES reservations(id) ON DELETE CASCADE,
  amount_vnd bigint NOT NULL,
  reason text NOT NULL CHECK (reason IN ('host_cancelled', 'guest_cancelled', 'dispute')),
  status text NOT NULL DEFAULT 'owed' CHECK (status IN ('owed', 'host_marked_sent', 'guest_confirmed', 'disputed', 'waived')),
  host_marked_at timestamptz,
  guest_confirmed_at timestamptz,
  note text
);
ALTER TABLE refund_claims ENABLE ROW LEVEL SECURITY;
CREATE POLICY refund_claims_participant_read ON refund_claims FOR SELECT TO authenticated USING (
  EXISTS (SELECT 1 FROM reservations r WHERE r.id = reservation_id AND r.user_id = auth.uid())
  OR EXISTS (SELECT 1 FROM reservations r JOIN events e ON e.id = r.event_id JOIN organizers o ON o.id = e.organizer_id WHERE r.id = reservation_id AND o.owner_id = auth.uid())
);

CREATE TABLE IF NOT EXISTS banbe_threads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id text NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  guest_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  organizer_id text NOT NULL REFERENCES organizers(id) ON DELETE CASCADE,
  UNIQUE(event_id, guest_id)
);
ALTER TABLE banbe_threads ENABLE ROW LEVEL SECURITY;
CREATE POLICY banbe_threads_read ON banbe_threads FOR SELECT TO authenticated USING (
  guest_id = auth.uid() OR EXISTS (SELECT 1 FROM organizers o WHERE o.id = organizer_id AND o.owner_id = auth.uid())
);
CREATE TABLE IF NOT EXISTS banbe_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  thread_id uuid NOT NULL REFERENCES banbe_threads(id) ON DELETE CASCADE,
  sender_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  body text NOT NULL,
  kind text NOT NULL DEFAULT 'text' CHECK (kind IN ('text', 'system')),
  created_at timestamptz NOT NULL DEFAULT now(),
  read_at timestamptz
);
ALTER TABLE banbe_messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY banbe_messages_read ON banbe_messages FOR SELECT TO authenticated USING (
  EXISTS (SELECT 1 FROM banbe_threads t WHERE t.id = thread_id AND (t.guest_id = auth.uid() OR EXISTS (SELECT 1 FROM organizers o WHERE o.id = t.organizer_id AND o.owner_id = auth.uid())))
);
CREATE POLICY banbe_messages_insert ON banbe_messages FOR INSERT TO authenticated WITH CHECK (
  sender_id = auth.uid() AND EXISTS (SELECT 1 FROM banbe_threads t WHERE t.id = thread_id AND (t.guest_id = auth.uid() OR EXISTS (SELECT 1 FROM organizers o WHERE o.id = t.organizer_id AND o.owner_id = auth.uid())))
);

ALTER TABLE chats ADD COLUMN IF NOT EXISTS sender_id uuid REFERENCES profiles(id) ON DELETE SET NULL;
ALTER TABLE chats ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public chats insert" ON chats;
DROP POLICY IF EXISTS "Public chats read" ON chats;
DROP POLICY IF EXISTS chats_participant_read ON chats;
CREATE POLICY chats_participant_read ON chats FOR SELECT TO authenticated USING (
  sender_id = auth.uid()
  OR EXISTS (SELECT 1 FROM reservations r WHERE r.event_id = chats.event_id AND r.user_id = auth.uid())
  OR EXISTS (SELECT 1 FROM events e JOIN organizers o ON o.id = e.organizer_id WHERE e.id = chats.event_id AND o.owner_id = auth.uid())
  OR EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
);
DROP POLICY IF EXISTS chats_participant_insert ON chats;
CREATE POLICY chats_participant_insert ON chats FOR INSERT TO authenticated WITH CHECK (
  sender_id = auth.uid()
  AND (
    EXISTS (SELECT 1 FROM reservations r WHERE r.event_id = chats.event_id AND r.user_id = auth.uid())
    OR EXISTS (SELECT 1 FROM events e JOIN organizers o ON o.id = e.organizer_id WHERE e.id = chats.event_id AND o.owner_id = auth.uid())
  )
);
REVOKE UPDATE, DELETE ON chats FROM anon, authenticated;

DO $$
BEGIN
  BEGIN
    INSERT INTO storage.buckets (id, name, public) VALUES ('event-photos', 'event-photos', true) ON CONFLICT (id) DO NOTHING;
    INSERT INTO storage.buckets (id, name, public) VALUES ('pay-qr', 'pay-qr', false) ON CONFLICT (id) DO NOTHING;
  EXCEPTION WHEN undefined_table OR insufficient_privilege THEN NULL;
  END;
END;
$$;

DO $$
BEGIN
  BEGIN
    EXECUTE 'CREATE EXTENSION IF NOT EXISTS pg_cron';
    PERFORM cron.schedule('banbe-expire-reservations', '* * * * *', 'select public.expire_reservations()');
  EXCEPTION WHEN duplicate_object OR undefined_table OR undefined_function OR insufficient_privilege THEN NULL;
  END;
END;
$$;

CREATE OR REPLACE VIEW v_event_availability AS
SELECT e.id, e.slug, e.total_seats,
  COALESCE(SUM(CASE WHEN r.status IN ('confirmed', 'paid', 'checked_in') OR (r.status IN ('pending', 'held') AND COALESCE(r.expires_at, r.hold_deadline) > now()) THEN r.qty ELSE 0 END), 0)::int AS live_claims,
  GREATEST(e.total_seats - COALESCE(SUM(CASE WHEN r.status IN ('confirmed', 'paid', 'checked_in') OR (r.status IN ('pending', 'held') AND COALESCE(r.expires_at, r.hold_deadline) > now()) THEN r.qty ELSE 0 END), 0), 0)::int AS seats_left
FROM events e LEFT JOIN reservations r ON r.event_id = e.id GROUP BY e.id;
CREATE INDEX IF NOT EXISTS reservations_event_status_idx ON reservations(event_id, status);
CREATE INDEX IF NOT EXISTS reservations_user_idx ON reservations(user_id);
CREATE INDEX IF NOT EXISTS events_status_idx ON events(status, created_at);

CREATE OR REPLACE FUNCTION enforce_reservation_transition() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF OLD.status = NEW.status THEN RETURN NEW; END IF;
  IF NOT (
    (OLD.status IN ('pending', 'held') AND NEW.status IN ('confirmed', 'paid', 'cancelled', 'expired', 'released'))
    OR (OLD.status IN ('confirmed', 'paid') AND NEW.status IN ('checked_in', 'no_show', 'cancelled'))
  ) THEN RAISE EXCEPTION 'ILLEGAL_RESERVATION_TRANSITION'; END IF;
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS reservation_status_transition ON reservations;
CREATE TRIGGER reservation_status_transition BEFORE UPDATE OF status ON reservations
FOR EACH ROW EXECUTE FUNCTION enforce_reservation_transition();

CREATE OR REPLACE FUNCTION claim_seats(p_event text, p_qty int, p_note text DEFAULT NULL)
RETURNS reservations LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_event events%ROWTYPE; v_taken int; v_reservation reservations%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'AUTH_REQUIRED'; END IF;
  IF p_qty IS NULL OR p_qty < 1 OR p_qty > 6 THEN RAISE EXCEPTION 'INVALID_QTY'; END IF;
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND phone_verified) THEN RAISE EXCEPTION 'PHONE_REQUIRED'; END IF;
  SELECT * INTO v_event FROM events WHERE id = p_event OR slug = p_event FOR UPDATE;
  IF NOT FOUND OR v_event.status <> 'live' THEN RAISE EXCEPTION 'NOT_LIVE'; END IF;
  IF EXISTS (SELECT 1 FROM reservations WHERE event_id = v_event.id AND user_id = auth.uid() AND status IN ('pending', 'held') AND COALESCE(expires_at, hold_deadline) > now()) THEN RAISE EXCEPTION 'PENDING_EXISTS'; END IF;
  SELECT COALESCE(SUM(qty), 0) INTO v_taken FROM reservations WHERE event_id = v_event.id AND (status IN ('confirmed', 'paid', 'checked_in') OR (status IN ('pending', 'held') AND COALESCE(expires_at, hold_deadline) > now()));
  IF v_taken + p_qty > v_event.total_seats THEN RAISE EXCEPTION 'SOLD_OUT'; END IF;
  INSERT INTO reservations(event_id, user_id, user_name, user_email, qty, status, pay_mode, total_vnd, code, guest_note, expires_at, confirmed_at)
  SELECT v_event.id, auth.uid(), COALESCE(p.display_name, ''), COALESCE(p.email, ''), p_qty,
    CASE WHEN v_event.approval = 'instant' THEN 'confirmed' ELSE 'pending' END,
    'collect_direct', p_qty * v_event.price_vnd,
    upper(substr(md5(gen_random_uuid()::text), 1, 6)), p_note,
    CASE WHEN v_event.approval = 'instant' THEN NULL ELSE now() + make_interval(mins => v_event.hold_minutes) END,
    CASE WHEN v_event.approval = 'instant' THEN now() ELSE NULL END
  FROM profiles p WHERE p.id = auth.uid() RETURNING * INTO v_reservation;
  INSERT INTO banbe_threads(event_id, guest_id, organizer_id) VALUES (v_event.id, auth.uid(), v_event.organizer_id) ON CONFLICT DO NOTHING;
  RETURN v_reservation;
END;
$$;
REVOKE EXECUTE ON FUNCTION claim_seats(text, int, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION claim_seats(text, int, text) TO authenticated;

CREATE OR REPLACE FUNCTION expire_reservations() RETURNS int LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_count int;
BEGIN
  UPDATE reservations SET status = 'expired' WHERE status IN ('pending', 'held') AND COALESCE(expires_at, hold_deadline) <= now();
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;
REVOKE EXECUTE ON FUNCTION expire_reservations() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION expire_reservations() TO authenticated;

CREATE OR REPLACE FUNCTION cancel_event(p_event text, p_reason text) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_reservation reservations%ROWTYPE;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM events e JOIN organizers o ON o.id = e.organizer_id WHERE e.id = p_event AND o.owner_id = auth.uid())
    AND NOT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin') THEN
    RETURN jsonb_build_object('success', false, 'error', 'NOT_AUTHORIZED');
  END IF;
  UPDATE events SET status = 'cancelled', is_cancelled = true, cancel_reason = p_reason, cancelled_at = now() WHERE id = p_event;
  FOR v_reservation IN SELECT * FROM reservations WHERE event_id = p_event AND status IN ('pending', 'held', 'confirmed', 'paid') LOOP
    UPDATE reservations SET status = 'cancelled', cancelled_at = now(), cancelled_by = auth.uid(), cancel_reason = p_reason WHERE id = v_reservation.id;
    IF v_reservation.status IN ('confirmed', 'paid') THEN
      INSERT INTO refund_claims(reservation_id, amount_vnd, reason) VALUES (v_reservation.id, COALESCE(v_reservation.total_vnd, v_reservation.qty * 0), 'host_cancelled');
    END IF;
  END LOOP;
  RETURN jsonb_build_object('success', true);
END;
$$;
REVOKE EXECUTE ON FUNCTION cancel_event(text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION cancel_event(text, text) TO authenticated;

CREATE OR REPLACE FUNCTION update_refund_claim(p_claim uuid, p_action text, p_note text DEFAULT NULL) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_claim refund_claims%ROWTYPE;
BEGIN
  SELECT * INTO v_claim FROM refund_claims WHERE id = p_claim;
  IF NOT FOUND THEN RETURN jsonb_build_object('success', false, 'error', 'CLAIM_NOT_FOUND'); END IF;
  IF p_action = 'host_marked_sent' AND EXISTS (SELECT 1 FROM reservations r JOIN events e ON e.id = r.event_id JOIN organizers o ON o.id = e.organizer_id WHERE r.id = v_claim.reservation_id AND o.owner_id = auth.uid()) THEN
    UPDATE refund_claims SET status = 'host_marked_sent', host_marked_at = now(), note = p_note WHERE id = p_claim;
  ELSIF p_action IN ('guest_confirmed', 'disputed') AND EXISTS (SELECT 1 FROM reservations r WHERE r.id = v_claim.reservation_id AND r.user_id = auth.uid()) THEN
    UPDATE refund_claims SET status = p_action, guest_confirmed_at = CASE WHEN p_action = 'guest_confirmed' THEN now() ELSE guest_confirmed_at END, note = p_note WHERE id = p_claim;
  ELSE
    RETURN jsonb_build_object('success', false, 'error', 'NOT_AUTHORIZED');
  END IF;
  RETURN jsonb_build_object('success', true);
END;
$$;
REVOKE EXECUTE ON FUNCTION update_refund_claim(uuid, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION update_refund_claim(uuid, text, text) TO authenticated;

CREATE OR REPLACE FUNCTION confirm_payment(p_reservation uuid, p_method text) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM reservations r JOIN events e ON e.id = r.event_id JOIN organizers o ON o.id = e.organizer_id WHERE r.id = p_reservation AND o.owner_id = auth.uid()) THEN
    RETURN jsonb_build_object('success', false, 'error', 'NOT_AUTHORIZED');
  END IF;
  UPDATE reservations SET status = 'confirmed', paid_marked_at = now(), paid_method = p_method, paid_marked_by = auth.uid(), confirmed_at = now()
  WHERE id = p_reservation AND status IN ('pending', 'held') AND COALESCE(expires_at, hold_deadline) > now();
  IF NOT FOUND THEN RETURN jsonb_build_object('success', false, 'error', 'RESERVATION_NOT_PENDING'); END IF;
  RETURN jsonb_build_object('success', true);
END;
$$;
REVOKE EXECUTE ON FUNCTION confirm_payment(uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION confirm_payment(uuid, text) TO authenticated;

CREATE OR REPLACE FUNCTION approve_event(p_event text) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin') THEN RETURN jsonb_build_object('success', false, 'error', 'NOT_AUTHORIZED'); END IF;
  UPDATE events SET status = 'live' WHERE id = p_event AND status IN ('draft', 'review');
  IF NOT FOUND THEN RETURN jsonb_build_object('success', false, 'error', 'EVENT_NOT_REVIEWABLE'); END IF;
  RETURN jsonb_build_object('success', true);
END;
$$;
REVOKE EXECUTE ON FUNCTION approve_event(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION approve_event(text) TO authenticated;

CREATE OR REPLACE FUNCTION check_in(p_code text, p_no_show boolean DEFAULT false) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_reservation reservations%ROWTYPE;
BEGIN
  SELECT r.* INTO v_reservation FROM reservations r JOIN events e ON e.id = r.event_id JOIN organizers o ON o.id = e.organizer_id WHERE r.code = upper(p_code) AND o.owner_id = auth.uid();
  IF NOT FOUND OR v_reservation.status NOT IN ('confirmed', 'paid') THEN RETURN jsonb_build_object('success', false, 'error', 'RESERVATION_NOT_CHECKABLE'); END IF;
  UPDATE reservations SET status = CASE WHEN p_no_show THEN 'no_show' ELSE 'checked_in' END, checked_in_at = CASE WHEN p_no_show THEN NULL ELSE now() END WHERE id = v_reservation.id;
  RETURN jsonb_build_object('success', true, 'reservation_id', v_reservation.id);
END;
$$;
REVOKE EXECUTE ON FUNCTION check_in(text, boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION check_in(text, boolean) TO authenticated;

CREATE OR REPLACE FUNCTION create_event_draft(
  p_name text, p_category text, p_description text, p_location text,
  p_event_date date, p_event_time time, p_price_vnd int, p_capacity int,
  p_organizer_name text, p_instagram text DEFAULT '', p_about text DEFAULT ''
) RETURNS events LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_org organizers%ROWTYPE; v_event events%ROWTYPE; v_id text; v_slug text;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'AUTH_REQUIRED'; END IF;
  IF p_name IS NULL OR length(trim(p_name)) = 0 OR p_capacity IS NULL OR p_capacity < 1 THEN RAISE EXCEPTION 'INVALID_EVENT'; END IF;
  UPDATE profiles SET role = CASE WHEN role = 'participant' THEN 'organizer' ELSE role END WHERE id = auth.uid();
  SELECT * INTO v_org FROM organizers WHERE owner_id = auth.uid() LIMIT 1;
  IF NOT FOUND THEN
    INSERT INTO organizers(id, owner_id, name, ig, description) VALUES (gen_random_uuid()::text, auth.uid(), COALESCE(NULLIF(trim(p_organizer_name), ''), 'Organizer'), p_instagram, p_about) RETURNING * INTO v_org;
  END IF;
  v_id := gen_random_uuid()::text;
  v_slug := lower(regexp_replace(trim(p_name), '[^a-zA-Z0-9]+', '-', 'g')) || '-' || substr(md5(v_id), 1, 6);
  INSERT INTO events(id, slug, cat_key, cat_name, title, district, date_short, date_long, event_time, price_vnd, price_text, total_seats, available_seats, description, organizer_id, status, approval)
  VALUES (v_id, v_slug, p_category, p_category, trim(p_name), COALESCE(p_location, ''), COALESCE(p_event_date::text, ''), COALESCE(p_event_date::text, ''), COALESCE(p_event_time::text, ''), COALESCE(p_price_vnd, 0), CASE WHEN COALESCE(p_price_vnd, 0) = 0 THEN 'Miễn phí' ELSE p_price_vnd::text || '₫' END, p_capacity, p_capacity, COALESCE(p_description, ''), v_org.id, 'review', 'host_approves') RETURNING * INTO v_event;
  RETURN v_event;
END;
$$;
REVOKE EXECUTE ON FUNCTION create_event_draft(text, text, text, text, date, time, int, int, text, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION create_event_draft(text, text, text, text, date, time, int, int, text, text, text) TO authenticated;

-- The supplied database has public reservation/chat policies. They are intentionally
-- removed above; all writes now go through authenticated RPCs and RLS-scoped reads.
