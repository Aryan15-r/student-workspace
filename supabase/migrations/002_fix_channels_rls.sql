-- ============================================================
-- Migration 002: Add Channel Creation RLS Policy
-- HOW TO USE: Paste this into Supabase SQL Editor and click Run
-- ============================================================

-- 1. Allow authenticated users to create channels for study rooms / communities
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'channels' AND policyname = 'Authenticated users can create channels'
  ) THEN
    CREATE POLICY "Authenticated users can create channels"
      ON public.channels FOR INSERT
      WITH CHECK (auth.uid() IS NOT NULL);
  END IF;
END $$;

-- 2. Allow authenticated users to update channels if needed
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'channels' AND policyname = 'Authenticated users can update channels'
  ) THEN
    CREATE POLICY "Authenticated users can update channels"
      ON public.channels FOR UPDATE
      USING (auth.uid() IS NOT NULL);
  END IF;
END $$;
