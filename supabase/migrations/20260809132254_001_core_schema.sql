/*
# Core schema for Góc — events platform

Creates the foundational tables for a multi-user events platform with three
roles: goers, hosts, and admins. All data that was previously hardcoded in
events.js now lives here.

## Tables created
1. profiles — user identity + role (goer / host / admin), linked to auth.users
2. organizers — host public pages (name, Instagram, bio, verification)
3. events — gatherings (name, category, price, capacity, location, datetime, status)
4. event_categories — secondary category for paid placement (max 2 per event)
5. reservations — bookings (event, goer, qty, pay mode, status, hold deadline)
6. payments — transactions tied to reservations (provider, amount, provider ref)
7. favorites — saved events per goer
8. follows — organizer follows per goer
9. messages — chat threads between goer and host
10. checkins — door check-in records
11. invitations — invite-only event links

## Security
- RLS enabled on every table
- profiles: each user reads/updates own row; role column is NOT client-writable
- organizers: public read; host can insert/update own; admin can update all
- events: public read of approved events; host can insert/update own; admin can update all
- reservations: goer sees own; host sees reservations for own events
- payments: goer sees own; host sees payments for own events
- favorites/follows: goer sees own only
- messages: participants see their own threads
- checkins: host sees checkins for own events
- invitations: goer sees own invites; host sees invites for own events
*/

-- ============ profiles ============
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL,
  display_name text NOT NULL DEFAULT '',
  role text NOT NULL DEFAULT 'goer' CHECK (role IN ('goer','host','admin')),
  phone text DEFAULT '',
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "profiles_select_own" ON profiles;
CREATE POLICY "profiles_select_own" ON profiles FOR SELECT
  TO authenticated USING (auth.uid() = id);

DROP POLICY IF EXISTS "profiles_insert_own" ON profiles;
CREATE POLICY "profiles_insert_own" ON profiles FOR INSERT
  TO authenticated WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "profiles_update_own" ON profiles;
CREATE POLICY "profiles_update_own" ON profiles FOR UPDATE
  TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- Prevent clients from writing the role column directly
REVOKE UPDATE ON profiles FROM authenticated;
GRANT UPDATE (display_name, phone) ON profiles TO authenticated;

-- ============ organizers ============
CREATE TABLE IF NOT EXISTS organizers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  name text NOT NULL,
  ig_handle text DEFAULT '',
  bio text DEFAULT '',
  verified boolean NOT NULL DEFAULT false,
  verified_at timestamptz,
  hosting_since int,
  event_count int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE organizers ENABLE ROW LEVEL SECURITY;

-- Public read of organizer pages
DROP POLICY IF EXISTS "organizers_select_public" ON organizers;
CREATE POLICY "organizers_select_public" ON organizers FOR SELECT
  TO anon, authenticated USING (true);

-- Host can insert own organizer profile
DROP POLICY IF EXISTS "organizers_insert_own" ON organizers;
CREATE POLICY "organizers_insert_own" ON organizers FOR INSERT
  TO authenticated WITH CHECK (auth.uid() = user_id);

-- Host can update own organizer profile (but not verified/verified_at — those are admin-only)
DROP POLICY IF EXISTS "organizers_update_own" ON organizers;
CREATE POLICY "organizers_update_own" ON organizers FOR UPDATE
  TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

REVOKE UPDATE ON organizers FROM authenticated;
GRANT UPDATE (name, ig_handle, bio, hosting_since) ON organizers TO authenticated;

-- ============ events ============
CREATE TABLE IF NOT EXISTS events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  key text UNIQUE,  -- stable slug matching old frontend keys (e.g. 'bepnho')
  organizer_id uuid REFERENCES organizers(id) ON DELETE SET NULL,
  name text NOT NULL,
  cat_key text NOT NULL,          -- supper / fashion / gallery / music
  cat_label text NOT NULL,        -- Vietnamese display label
  description text DEFAULT '',
  included text DEFAULT '',       -- what's included
  price_text text DEFAULT '',     -- display string e.g. '900.000₫' or 'Miễn phí'
  price_cents bigint NOT NULL DEFAULT 0,  -- numeric price in VND cents for payment
  is_free boolean NOT NULL DEFAULT false,
  capacity int NOT NULL DEFAULT 0,
  seats_remaining int NOT NULL DEFAULT 0,
  location text DEFAULT '',
  area text DEFAULT '',           -- Bình Thạnh / Quận 1 / Thảo Điền etc.
  km_text text DEFAULT '',        -- display distance
  day_short text DEFAULT '',      -- 'Th 7, 11.07'
  day_long text DEFAULT '',       -- 'Thứ Bảy, 11 tháng 7'
  time_text text DEFAULT '',      -- '19:00'
  event_date date,
  event_time time,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','open','sold_out','cancelled','ended')),
  invite_only boolean NOT NULL DEFAULT false,
  greeting text DEFAULT '',       -- host's default chat greeting
  hero_photo text DEFAULT '',
  gallery jsonb NOT NULL DEFAULT '[]',
  org_gallery jsonb NOT NULL DEFAULT '[]',
  host_name text DEFAULT '',
  host_short text DEFAULT '',
  palette text DEFAULT 'concrete',
  cancelled_hours_ago int,
  ended_hours_ago int,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE events ENABLE ROW LEVEL SECURITY;

-- Public read of approved/open events (pending events only visible to owner+admin)
DROP POLICY IF EXISTS "events_select_public" ON events;
CREATE POLICY "events_select_public" ON events FOR SELECT
  TO anon, authenticated USING (
    status IN ('open','sold_out','cancelled','ended')
    OR EXISTS (SELECT 1 FROM organizers o WHERE o.id = events.organizer_id AND o.user_id = auth.uid())
    OR EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

-- Host can insert events for own organizer
DROP POLICY IF EXISTS "events_insert_own" ON events;
CREATE POLICY "events_insert_own" ON events FOR INSERT
  TO authenticated WITH CHECK (
    EXISTS (SELECT 1 FROM organizers o WHERE o.id = organizer_id AND o.user_id = auth.uid())
    OR EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

-- Host can update own events; admin can update all
DROP POLICY IF EXISTS "events_update_own" ON events;
CREATE POLICY "events_update_own" ON events FOR UPDATE
  TO authenticated USING (
    EXISTS (SELECT 1 FROM organizers o WHERE o.id = events.organizer_id AND o.user_id = auth.uid())
    OR EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  ) WITH CHECK (
    EXISTS (SELECT 1 FROM organizers o WHERE o.id = events.organizer_id AND o.user_id = auth.uid())
    OR EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

-- Host can delete own events
DROP POLICY IF EXISTS "events_delete_own" ON events;
CREATE POLICY "events_delete_own" ON events FOR DELETE
  TO authenticated USING (
    EXISTS (SELECT 1 FROM organizers o WHERE o.id = events.organizer_id AND o.user_id = auth.uid())
    OR EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

-- ============ event_categories (paid placement, max 2 per event) ============
CREATE TABLE IF NOT EXISTS event_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  cat_key text NOT NULL,
  cat_label text NOT NULL,
  sort_order int NOT NULL DEFAULT 0
);
ALTER TABLE event_categories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "event_categories_select_public" ON event_categories;
CREATE POLICY "event_categories_select_public" ON event_categories FOR SELECT
  TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "event_categories_insert_own" ON event_categories;
CREATE POLICY "event_categories_insert_own" ON event_categories FOR INSERT
  TO authenticated WITH CHECK (
    EXISTS (SELECT 1 FROM events e WHERE e.id = event_id
            AND EXISTS (SELECT 1 FROM organizers o WHERE o.id = e.organizer_id AND o.user_id = auth.uid()))
  );

DROP POLICY IF EXISTS "event_categories_delete_own" ON event_categories;
CREATE POLICY "event_categories_delete_own" ON event_categories FOR DELETE
  TO authenticated USING (
    EXISTS (SELECT 1 FROM events e WHERE e.id = event_id
            AND EXISTS (SELECT 1 FROM organizers o WHERE o.id = e.organizer_id AND o.user_id = auth.uid()))
  );

-- ============ reservations ============
CREATE TABLE IF NOT EXISTS reservations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  user_name text NOT NULL DEFAULT '',
  user_email text NOT NULL DEFAULT '',
  user_phone text DEFAULT '',
  qty int NOT NULL DEFAULT 1 CHECK (qty >= 1 AND qty <= 6),
  pay_mode text NOT NULL DEFAULT 'now' CHECK (pay_mode IN ('now','hold_24h')),
  status text NOT NULL DEFAULT 'held' CHECK (status IN ('held','paid','refunded','checked_in','released','cancelled')),
  hold_deadline timestamptz,
  total_cents bigint NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE reservations ENABLE ROW LEVEL SECURITY;

-- Goer sees own reservations; host sees reservations for own events
DROP POLICY IF EXISTS "reservations_select_own" ON reservations;
CREATE POLICY "reservations_select_own" ON reservations FOR SELECT
  TO authenticated USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM events e WHERE e.id = reservations.event_id
      AND EXISTS (SELECT 1 FROM organizers o WHERE o.id = e.organizer_id AND o.user_id = auth.uid())
    )
    OR EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

-- Goer can insert own reservations
DROP POLICY IF EXISTS "reservations_insert_own" ON reservations;
CREATE POLICY "reservations_insert_own" ON reservations FOR INSERT
  TO authenticated WITH CHECK (auth.uid() = user_id);

-- Goer can update own reservations (limited); host/admin via functions
DROP POLICY IF EXISTS "reservations_update_own" ON reservations;
CREATE POLICY "reservations_update_own" ON reservations FOR UPDATE
  TO authenticated USING (
    auth.uid() = user_id
    OR EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  ) WITH CHECK (
    auth.uid() = user_id
    OR EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

REVOKE UPDATE ON reservations FROM authenticated;
GRANT UPDATE (user_name, user_email, user_phone) ON reservations TO authenticated;

-- ============ payments ============
CREATE TABLE IF NOT EXISTS payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reservation_id uuid NOT NULL REFERENCES reservations(id) ON DELETE CASCADE,
  provider text NOT NULL DEFAULT 'stripe' CHECK (provider IN ('stripe','momo','vnpay','zalopay','halopay','apple_pay','card')),
  amount_cents bigint NOT NULL DEFAULT 0,
  currency text NOT NULL DEFAULT 'vnd',
  provider_ref text,          -- Stripe checkout session ID / gateway ref
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','succeeded','failed','refunded')),
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "payments_select_own" ON payments;
CREATE POLICY "payments_select_own" ON payments FOR SELECT
  TO authenticated USING (
    EXISTS (SELECT 1 FROM reservations r WHERE r.id = reservation_id AND r.user_id = auth.uid())
    OR EXISTS (
      SELECT 1 FROM reservations r
      JOIN events e ON e.id = r.event_id
      JOIN organizers o ON o.id = e.organizer_id
      WHERE r.id = reservation_id AND o.user_id = auth.uid()
    )
    OR EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

-- ============ favorites ============
CREATE TABLE IF NOT EXISTS favorites (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  event_id uuid NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(user_id, event_id)
);
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "favorites_select_own" ON favorites;
CREATE POLICY "favorites_select_own" ON favorites FOR SELECT
  TO authenticated USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "favorites_insert_own" ON favorites;
CREATE POLICY "favorites_insert_own" ON favorites FOR INSERT
  TO authenticated WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "favorites_delete_own" ON favorites;
CREATE POLICY "favorites_delete_own" ON favorites FOR DELETE
  TO authenticated USING (auth.uid() = user_id);

-- ============ follows ============
CREATE TABLE IF NOT EXISTS follows (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  organizer_id uuid NOT NULL REFERENCES organizers(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(user_id, organizer_id)
);
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "follows_select_own" ON follows;
CREATE POLICY "follows_select_own" ON follows FOR SELECT
  TO authenticated USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "follows_insert_own" ON follows;
CREATE POLICY "follows_insert_own" ON follows FOR INSERT
  TO authenticated WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "follows_delete_own" ON follows;
CREATE POLICY "follows_delete_own" ON follows FOR DELETE
  TO authenticated USING (auth.uid() = user_id);

-- ============ messages ============
CREATE TABLE IF NOT EXISTS messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  sender_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  recipient_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  body text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Participants see messages in threads they're part of
DROP POLICY IF EXISTS "messages_select_own" ON messages;
CREATE POLICY "messages_select_own" ON messages FOR SELECT
  TO authenticated USING (
    auth.uid() = sender_id
    OR auth.uid() = recipient_id
    OR EXISTS (
      SELECT 1 FROM events e WHERE e.id = messages.event_id
      AND EXISTS (SELECT 1 FROM organizers o WHERE o.id = e.organizer_id AND o.user_id = auth.uid())
    )
  );

DROP POLICY IF EXISTS "messages_insert_own" ON messages;
CREATE POLICY "messages_insert_own" ON messages FOR INSERT
  TO authenticated WITH CHECK (auth.uid() = sender_id);

-- ============ checkins ============
CREATE TABLE IF NOT EXISTS checkins (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reservation_id uuid NOT NULL REFERENCES reservations(id) ON DELETE CASCADE,
  event_id uuid NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  checked_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(reservation_id)
);
ALTER TABLE checkins ENABLE ROW LEVEL SECURITY;

-- Host sees checkins for own events; goer can see their own
DROP POLICY IF EXISTS "checkins_select_own" ON checkins;
CREATE POLICY "checkins_select_own" ON checkins FOR SELECT
  TO authenticated USING (
    EXISTS (SELECT 1 FROM reservations r WHERE r.id = reservation_id AND r.user_id = auth.uid())
    OR EXISTS (
      SELECT 1 FROM events e WHERE e.id = checkins.event_id
      AND EXISTS (SELECT 1 FROM organizers o WHERE o.id = e.organizer_id AND o.user_id = auth.uid())
    )
    OR EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

-- ============ invitations ============
CREATE TABLE IF NOT EXISTS invitations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  token text UNIQUE NOT NULL DEFAULT gen_random_uuid()::text,
  used_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE invitations ENABLE ROW LEVEL SECURITY;

-- Goer sees own invites; host sees invites for own events
DROP POLICY IF EXISTS "invitations_select_own" ON invitations;
CREATE POLICY "invitations_select_own" ON invitations FOR SELECT
  TO authenticated USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM events e WHERE e.id = invitations.event_id
      AND EXISTS (SELECT 1 FROM organizers o WHERE o.id = e.organizer_id AND o.user_id = auth.uid())
    )
    OR EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

DROP POLICY IF EXISTS "invitations_insert_own" ON invitations;
CREATE POLICY "invitations_insert_own" ON invitations FOR INSERT
  TO authenticated WITH CHECK (
    EXISTS (
      SELECT 1 FROM events e WHERE e.id = invitations.event_id
      AND EXISTS (SELECT 1 FROM organizers o WHERE o.id = e.organizer_id AND o.user_id = auth.uid())
    )
    OR EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

-- ============ Indexes ============
CREATE INDEX IF NOT EXISTS idx_events_organizer ON events(organizer_id);
CREATE INDEX IF NOT EXISTS idx_events_status ON events(status);
CREATE INDEX IF NOT EXISTS idx_events_key ON events(key);
CREATE INDEX IF NOT EXISTS idx_reservations_event ON reservations(event_id);
CREATE INDEX IF NOT EXISTS idx_reservations_user ON reservations(user_id);
CREATE INDEX IF NOT EXISTS idx_reservations_status ON reservations(status);
CREATE INDEX IF NOT EXISTS idx_payments_reservation ON payments(reservation_id);
CREATE INDEX IF NOT EXISTS idx_favorites_user ON favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_follows_user ON follows(user_id);
CREATE INDEX IF NOT EXISTS idx_messages_event ON messages(event_id);
CREATE INDEX IF NOT EXISTS idx_checkins_reservation ON checkins(reservation_id);
CREATE INDEX IF NOT EXISTS idx_checkins_event ON checkins(event_id);

-- ============ updated_at trigger for reservations ============
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS reservations_updated_at ON reservations;
CREATE TRIGGER reservations_updated_at
  BEFORE UPDATE ON reservations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
