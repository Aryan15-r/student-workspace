-- Restores signed-in study tracker state after app storage is cleared or the app
-- is reinstalled. Run this migration in the Supabase SQL editor.
CREATE TABLE IF NOT EXISTS public.study_tracker_states (
  user_id uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  remaining_seconds integer NOT NULL DEFAULT 1500 CHECK (remaining_seconds >= 0),
  is_running boolean NOT NULL DEFAULT false,
  target_end_at timestamptz,
  alarms jsonb NOT NULL DEFAULT '[]'::jsonb,
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.user_daily_stats (
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  date date NOT NULL,
  focused_seconds integer NOT NULL DEFAULT 0 CHECK (focused_seconds >= 0),
  attended boolean NOT NULL DEFAULT false,
  PRIMARY KEY (user_id, date)
);

ALTER TABLE public.study_tracker_states ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_daily_stats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage their own tracker state" ON public.study_tracker_states
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users manage their own daily stats" ON public.user_daily_stats
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Google returns `name` and `picture`; email/password registration uses the
-- existing `full_name` metadata. This makes a selected Google account populate
-- the profile automatically.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, username, full_name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', ''),
    COALESCE(NEW.raw_user_meta_data->>'avatar_url', NEW.raw_user_meta_data->>'picture', '')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
