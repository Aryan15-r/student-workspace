-- ============================================================
-- Migration 003: Private Rooms, Access Passcodes & Admin Chat Deletion
-- HOW TO USE: Go to your Supabase Dashboard → SQL Editor → Paste this file → Run
-- ============================================================

-- 1. Add Private Room and Passcode columns to communities
ALTER TABLE public.communities ADD COLUMN IF NOT EXISTS is_private boolean DEFAULT false;
ALTER TABLE public.communities ADD COLUMN IF NOT EXISTS passcode text DEFAULT '';

-- 2. Add Private Room, Passcode, and Created By columns to channels
ALTER TABLE public.channels ADD COLUMN IF NOT EXISTS is_private boolean DEFAULT false;
ALTER TABLE public.channels ADD COLUMN IF NOT EXISTS passcode text DEFAULT '';
ALTER TABLE public.channels ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL;

-- 3. Safely Enable Realtime Replication for messages (bypasses 42710 duplicate error if already added)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_rel pr
    JOIN pg_class c ON pr.prrelid = c.oid
    JOIN pg_publication p ON pr.prpubid = p.oid
    WHERE p.pubname = 'supabase_realtime' AND c.relname = 'messages'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
  END IF;
EXCEPTION
  WHEN OTHERS THEN NULL;
END $$;

-- 4. RLS Policy: Allow message author OR room creator (Admin) to delete messages
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'messages' AND policyname = 'Users and Room Admins can delete messages'
  ) THEN
    CREATE POLICY "Users and Room Admins can delete messages"
      ON public.messages FOR DELETE
      USING (
        auth.uid() = user_id 
        OR auth.uid() IN (
          SELECT c.created_by FROM public.channels ch
          JOIN public.communities c ON c.id = ch.community_id
          WHERE ch.id = messages.channel_id
        )
        OR auth.uid() IN (
          SELECT created_by FROM public.channels WHERE id = messages.channel_id
        )
      );
  END IF;
END $$;
