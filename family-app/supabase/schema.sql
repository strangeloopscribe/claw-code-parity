-- ============================================================
-- Family Hub – Supabase Schema
-- Run this in the Supabase SQL editor to set up the database.
-- ============================================================

-- ── Profiles ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL,
  avatar_url  TEXT,
  color       TEXT NOT NULL DEFAULT '#FF7043',
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all profiles in their family"
  ON public.profiles FOR SELECT
  USING (
    id IN (
      SELECT fm.profile_id FROM public.family_members fm
      WHERE fm.family_id IN (
        SELECT family_id FROM public.family_members WHERE profile_id = auth.uid()
      )
    )
    OR id = auth.uid()
  );

CREATE POLICY "Users can update their own profile"
  ON public.profiles FOR UPDATE USING (id = auth.uid());

CREATE POLICY "Users can insert their own profile"
  ON public.profiles FOR INSERT WITH CHECK (id = auth.uid());

-- ── Families ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.families (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,
  created_by  UUID REFERENCES public.profiles(id),
  invite_code TEXT UNIQUE DEFAULT upper(substring(md5(random()::text), 1, 8)),
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.families ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Family members can view their family"
  ON public.families FOR SELECT
  USING (
    id IN (SELECT family_id FROM public.family_members WHERE profile_id = auth.uid())
  );

CREATE POLICY "Authenticated users can create families"
  ON public.families FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Family admins can update family"
  ON public.families FOR UPDATE
  USING (
    id IN (
      SELECT family_id FROM public.family_members
      WHERE profile_id = auth.uid() AND role = 'admin'
    )
  );

-- ── Family Members ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.family_members (
  family_id   UUID REFERENCES public.families(id) ON DELETE CASCADE,
  profile_id  UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  role        TEXT NOT NULL DEFAULT 'member',  -- 'admin' | 'member'
  joined_at   TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (family_id, profile_id)
);

ALTER TABLE public.family_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Family members can view membership"
  ON public.family_members FOR SELECT
  USING (
    family_id IN (SELECT family_id FROM public.family_members WHERE profile_id = auth.uid())
  );

CREATE POLICY "Users can join families"
  ON public.family_members FOR INSERT WITH CHECK (profile_id = auth.uid());

CREATE POLICY "Admins can remove members"
  ON public.family_members FOR DELETE
  USING (
    family_id IN (
      SELECT family_id FROM public.family_members
      WHERE profile_id = auth.uid() AND role = 'admin'
    )
    OR profile_id = auth.uid()
  );

-- ── Events (Calendar) ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.events (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id   UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
  created_by  UUID REFERENCES public.profiles(id),
  title       TEXT NOT NULL,
  description TEXT,
  location    TEXT,
  start_time  TIMESTAMPTZ NOT NULL,
  end_time    TIMESTAMPTZ,
  all_day     BOOLEAN NOT NULL DEFAULT false,
  color       TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Family members can view events"
  ON public.events FOR SELECT
  USING (
    family_id IN (SELECT family_id FROM public.family_members WHERE profile_id = auth.uid())
  );

CREATE POLICY "Family members can create events"
  ON public.events FOR INSERT
  WITH CHECK (
    family_id IN (SELECT family_id FROM public.family_members WHERE profile_id = auth.uid())
    AND created_by = auth.uid()
  );

CREATE POLICY "Event creator can update/delete"
  ON public.events FOR UPDATE USING (created_by = auth.uid());

CREATE POLICY "Event creator can delete"
  ON public.events FOR DELETE USING (created_by = auth.uid());

-- ── Lists ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.lists (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id   UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
  created_by  UUID REFERENCES public.profiles(id),
  name        TEXT NOT NULL,
  list_type   TEXT NOT NULL DEFAULT 'shopping',  -- 'shopping' | 'todo'
  color       TEXT NOT NULL DEFAULT '#26A69A',
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.lists ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Family members can view lists"
  ON public.lists FOR SELECT
  USING (
    family_id IN (SELECT family_id FROM public.family_members WHERE profile_id = auth.uid())
  );

CREATE POLICY "Family members can create lists"
  ON public.lists FOR INSERT
  WITH CHECK (
    family_id IN (SELECT family_id FROM public.family_members WHERE profile_id = auth.uid())
  );

CREATE POLICY "Family members can update lists"
  ON public.lists FOR UPDATE
  USING (
    family_id IN (SELECT family_id FROM public.family_members WHERE profile_id = auth.uid())
  );

CREATE POLICY "List creator can delete"
  ON public.lists FOR DELETE USING (created_by = auth.uid());

-- ── List Items ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.list_items (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  list_id      UUID NOT NULL REFERENCES public.lists(id) ON DELETE CASCADE,
  added_by     UUID REFERENCES public.profiles(id),
  text         TEXT NOT NULL,
  completed    BOOLEAN NOT NULL DEFAULT false,
  completed_by UUID REFERENCES public.profiles(id),
  completed_at TIMESTAMPTZ,
  position     INTEGER NOT NULL DEFAULT 0,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.list_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Family members can view list items"
  ON public.list_items FOR SELECT
  USING (
    list_id IN (
      SELECT l.id FROM public.lists l
      WHERE l.family_id IN (SELECT family_id FROM public.family_members WHERE profile_id = auth.uid())
    )
  );

CREATE POLICY "Family members can add items"
  ON public.list_items FOR INSERT
  WITH CHECK (
    list_id IN (
      SELECT l.id FROM public.lists l
      WHERE l.family_id IN (SELECT family_id FROM public.family_members WHERE profile_id = auth.uid())
    )
  );

CREATE POLICY "Family members can update items"
  ON public.list_items FOR UPDATE
  USING (
    list_id IN (
      SELECT l.id FROM public.lists l
      WHERE l.family_id IN (SELECT family_id FROM public.family_members WHERE profile_id = auth.uid())
    )
  );

CREATE POLICY "Family members can delete items"
  ON public.list_items FOR DELETE
  USING (
    list_id IN (
      SELECT l.id FROM public.lists l
      WHERE l.family_id IN (SELECT family_id FROM public.family_members WHERE profile_id = auth.uid())
    )
  );

-- Enable real-time for list_items
ALTER PUBLICATION supabase_realtime ADD TABLE public.list_items;

-- ── Journal Entries ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.journal_entries (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id   UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
  created_by  UUID REFERENCES public.profiles(id),
  title       TEXT,
  body        TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.journal_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Family members can view journal"
  ON public.journal_entries FOR SELECT
  USING (
    family_id IN (SELECT family_id FROM public.family_members WHERE profile_id = auth.uid())
  );

CREATE POLICY "Family members can create entries"
  ON public.journal_entries FOR INSERT
  WITH CHECK (
    family_id IN (SELECT family_id FROM public.family_members WHERE profile_id = auth.uid())
    AND created_by = auth.uid()
  );

CREATE POLICY "Entry creator can update/delete"
  ON public.journal_entries FOR UPDATE USING (created_by = auth.uid());

CREATE POLICY "Entry creator can delete"
  ON public.journal_entries FOR DELETE USING (created_by = auth.uid());

-- ── Journal Photos ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.journal_photos (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entry_id     UUID NOT NULL REFERENCES public.journal_entries(id) ON DELETE CASCADE,
  storage_path TEXT NOT NULL,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.journal_photos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Family members can view photos"
  ON public.journal_photos FOR SELECT
  USING (
    entry_id IN (
      SELECT je.id FROM public.journal_entries je
      WHERE je.family_id IN (SELECT family_id FROM public.family_members WHERE profile_id = auth.uid())
    )
  );

CREATE POLICY "Entry creator can add photos"
  ON public.journal_photos FOR INSERT
  WITH CHECK (
    entry_id IN (
      SELECT je.id FROM public.journal_entries je WHERE je.created_by = auth.uid()
    )
  );

CREATE POLICY "Entry creator can delete photos"
  ON public.journal_photos FOR DELETE
  USING (
    entry_id IN (
      SELECT je.id FROM public.journal_entries je WHERE je.created_by = auth.uid()
    )
  );

-- ── Storage bucket for journal photos ───────────────────────
-- Run in the Supabase dashboard → Storage → New bucket:
-- Name: journal-photos, Public: true
-- Or via SQL:
INSERT INTO storage.buckets (id, name, public)
VALUES ('journal-photos', 'journal-photos', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Family members can upload photos"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'journal-photos' AND auth.uid() IS NOT NULL);

CREATE POLICY "Anyone can view journal photos"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'journal-photos');

CREATE POLICY "Uploader can delete their photos"
  ON storage.objects FOR DELETE
  USING (bucket_id = 'journal-photos' AND owner = auth.uid());

-- ── Helper function: updated_at trigger ─────────────────────
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_events_updated_at
  BEFORE UPDATE ON public.events
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_journal_updated_at
  BEFORE UPDATE ON public.journal_entries
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
