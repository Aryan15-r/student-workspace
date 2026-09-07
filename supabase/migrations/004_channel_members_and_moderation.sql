-- ============================================================
-- Migration 004: Channel Members & Admin Moderation
-- HOW TO USE: Go to your Supabase Dashboard → SQL Editor → Paste this file → Run
-- ============================================================

-- 1. Create channel_members table if not exists
CREATE TABLE IF NOT EXISTS public.channel_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_id uuid REFERENCES public.channels(id) ON DELETE CASCADE,
  user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  role text DEFAULT 'member', -- 'admin' or 'member'
  joined_at timestamptz DEFAULT now(),
  UNIQUE(channel_id, user_id)
);

-- Enable RLS on channel_members
ALTER TABLE public.channel_members ENABLE ROW LEVEL SECURITY;

-- 2. Policies for channel_members
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'channel_members' AND policyname = 'Anyone authenticated can view members'
  ) THEN
    CREATE POLICY "Anyone authenticated can view members"
      ON public.channel_members FOR SELECT
      USING (auth.role() = 'authenticated');
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'channel_members' AND policyname = 'Users can join or leave channels'
  ) THEN
    CREATE POLICY "Users can join or leave channels"
      ON public.channel_members FOR INSERT
      WITH CHECK (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'channel_members' AND policyname = 'Users and Admins can delete memberships'
  ) THEN
    CREATE POLICY "Users and Admins can delete memberships"
      ON public.channel_members FOR DELETE
      USING (
        auth.uid() = user_id OR
        auth.uid() IN (
          SELECT user_id FROM public.channel_members WHERE channel_id = channel_members.channel_id AND role = 'admin'
        ) OR
        auth.uid() IN (
          SELECT created_by FROM public.channels WHERE id = channel_members.channel_id
        )
      );
  END IF;
END $$;

-- 3. Policy: Allow admins to delete channels & communities
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'channels' AND policyname = 'Admins can delete channels'
  ) THEN
    CREATE POLICY "Admins can delete channels"
      ON public.channels FOR DELETE
      USING (
        auth.uid() = created_by OR
        auth.uid() IN (
          SELECT c.created_by FROM public.communities c WHERE c.id = channels.community_id
        )
      );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'communities' AND policyname = 'Admins can delete communities'
  ) THEN
    CREATE POLICY "Admins can delete communities"
      ON public.communities FOR DELETE
      USING (auth.uid() = created_by);
  END IF;
END $$;
