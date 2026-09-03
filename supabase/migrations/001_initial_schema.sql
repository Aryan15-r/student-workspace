-- ============================================================
-- StudySpace — Complete Supabase Schema
-- HOW TO USE: Go to your Supabase project → SQL Editor → 
--             paste this entire file → click Run
-- ============================================================

-- Enable the UUID extension (needed for gen_random_uuid())
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";


-- ============================================================
-- TABLE: profiles
-- One profile per user, auto-created on signup (see trigger below)
-- ============================================================
CREATE TABLE public.profiles (
  id          uuid        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username    text        UNIQUE NOT NULL,
  full_name   text        DEFAULT '',
  avatar_url  text        DEFAULT '',
  bio         text        DEFAULT '',
  college     text        DEFAULT '',
  branch      text        DEFAULT '',
  year        integer     CHECK (year BETWEEN 1 AND 6),
  created_at  timestamptz DEFAULT now() NOT NULL,
  updated_at  timestamptz DEFAULT now() NOT NULL
);

COMMENT ON TABLE public.profiles IS 'One profile per user. Extends auth.users.';


-- ============================================================
-- TABLE: tasks
-- Personal to-do items for each user
-- ============================================================
CREATE TABLE public.tasks (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title       text        NOT NULL,
  description text        DEFAULT '',
  category    text        DEFAULT 'personal'
                          CHECK (category IN ('assignment','exam','project','personal','college')),
  priority    text        DEFAULT 'medium'
                          CHECK (priority IN ('low','medium','high')),
  due_date    date,
  completed   boolean     DEFAULT false NOT NULL,
  created_at  timestamptz DEFAULT now() NOT NULL,
  updated_at  timestamptz DEFAULT now() NOT NULL
);

COMMENT ON TABLE public.tasks IS 'Personal to-do list for each student.';


-- ============================================================
-- TABLE: communities
-- Top-level discussion groups (e.g. "Programming", "Math")
-- ============================================================
CREATE TABLE public.communities (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text        NOT NULL,
  description text        DEFAULT '',
  icon        text        DEFAULT '🎓',
  category    text        DEFAULT 'general',
  created_by  uuid        REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at  timestamptz DEFAULT now() NOT NULL
);

COMMENT ON TABLE public.communities IS 'Top-level discussion communities.';


-- ============================================================
-- TABLE: channels
-- Sub-channels within a community (e.g. #general, #homework-help)
-- ============================================================
CREATE TABLE public.channels (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  community_id  uuid        NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
  name          text        NOT NULL,
  description   text        DEFAULT '',
  created_at    timestamptz DEFAULT now() NOT NULL
);

COMMENT ON TABLE public.channels IS 'Discussion channels inside a community.';


-- ============================================================
-- TABLE: messages
-- Chat messages inside channels (Realtime enabled)
-- ============================================================
CREATE TABLE public.messages (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_id  uuid        NOT NULL REFERENCES public.channels(id) ON DELETE CASCADE,
  user_id     uuid        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content     text        NOT NULL,
  created_at  timestamptz DEFAULT now() NOT NULL,
  edited_at   timestamptz
);

COMMENT ON TABLE public.messages IS 'Chat messages with Realtime enabled.';


-- ============================================================
-- TABLE: message_reactions
-- Emoji reactions on messages
-- ============================================================
CREATE TABLE public.message_reactions (
  id          uuid  PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id  uuid  NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
  user_id     uuid  NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  emoji       text  NOT NULL,
  UNIQUE (message_id, user_id, emoji)   -- prevent duplicate reactions
);

COMMENT ON TABLE public.message_reactions IS 'Emoji reactions on messages.';


-- ============================================================
-- TABLE: search_history
-- Saves a user's past search queries
-- ============================================================
CREATE TABLE public.search_history (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  query       text        NOT NULL,
  created_at  timestamptz DEFAULT now() NOT NULL
);

COMMENT ON TABLE public.search_history IS 'User search history for "Recent searches".';


-- ============================================================
-- TABLE: reports
-- Moderation reports filed against messages
-- ============================================================
CREATE TABLE public.reports (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id   uuid        REFERENCES public.profiles(id) ON DELETE SET NULL,
  message_id    uuid        REFERENCES public.messages(id) ON DELETE CASCADE,
  reason        text        NOT NULL,
  created_at    timestamptz DEFAULT now() NOT NULL
);

COMMENT ON TABLE public.reports IS 'Moderation reports for community messages.';


-- ============================================================
-- INDEXES (speed up common queries)
-- ============================================================
CREATE INDEX idx_tasks_user_id              ON public.tasks(user_id);
CREATE INDEX idx_tasks_due_date             ON public.tasks(due_date);
CREATE INDEX idx_tasks_completed            ON public.tasks(completed);
CREATE INDEX idx_messages_channel_id        ON public.messages(channel_id);
CREATE INDEX idx_messages_created_at        ON public.messages(created_at DESC);
CREATE INDEX idx_channels_community_id      ON public.channels(community_id);
CREATE INDEX idx_search_history_user_id     ON public.search_history(user_id);
CREATE INDEX idx_message_reactions_msg_id   ON public.message_reactions(message_id);


-- ============================================================
-- FUNCTION: auto-update updated_at column
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach to profiles
CREATE TRIGGER on_profiles_updated
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Attach to tasks
CREATE TRIGGER on_tasks_updated
  BEFORE UPDATE ON public.tasks
  FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();


-- ============================================================
-- FUNCTION + TRIGGER: auto-create profile on user signup
-- When someone signs up, this trigger automatically creates
-- their profile row so we don't have to do it manually.
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, username, full_name, avatar_url)
  VALUES (
    NEW.id,
    -- Use the username from signup metadata, or fall back to email prefix
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'avatar_url', '')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();


-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- This is the most important security layer.
-- Each policy defines EXACTLY who can read/write each row.
-- ============================================================

-- ---- profiles ----
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view profiles"
  ON public.profiles FOR SELECT
  USING (true);

CREATE POLICY "Users can update only their own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);


-- ---- tasks ----
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users see only their own tasks"
  ON public.tasks FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create tasks for themselves"
  ON public.tasks FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own tasks"
  ON public.tasks FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own tasks"
  ON public.tasks FOR DELETE
  USING (auth.uid() = user_id);


-- ---- communities ----
ALTER TABLE public.communities ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view communities"
  ON public.communities FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can create communities"
  ON public.communities FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);


-- ---- channels ----
ALTER TABLE public.channels ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view channels"
  ON public.channels FOR SELECT
  USING (true);


-- ---- messages ----
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view messages"
  ON public.messages FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can send messages"
  ON public.messages FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can edit their own messages"
  ON public.messages FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own messages"
  ON public.messages FOR DELETE
  USING (auth.uid() = user_id);


-- ---- message_reactions ----
ALTER TABLE public.message_reactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view reactions"
  ON public.message_reactions FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can add reactions"
  ON public.message_reactions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can remove their own reactions"
  ON public.message_reactions FOR DELETE
  USING (auth.uid() = user_id);


-- ---- search_history ----
ALTER TABLE public.search_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users see only their own search history"
  ON public.search_history FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can add to their own search history"
  ON public.search_history FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own search history"
  ON public.search_history FOR DELETE
  USING (auth.uid() = user_id);


-- ---- reports ----
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can file reports"
  ON public.reports FOR INSERT
  WITH CHECK (auth.uid() = reporter_id);


-- ============================================================
-- REALTIME
-- Enable live updates for messages and reactions
-- ============================================================
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.message_reactions;


-- ============================================================
-- SEED DATA — Default Communities + Channels
-- These are created without a created_by (system-level)
-- ============================================================
INSERT INTO public.communities (name, description, icon, category) VALUES
  ('Programming',   'Code, algorithms, software development, and debugging',    '💻', 'tech'),
  ('Mathematics',   'Calculus, algebra, statistics, and more',                  '📐', 'science'),
  ('Physics',       'Mechanics, thermodynamics, electromagnetism',               '⚡', 'science'),
  ('Engineering',   'All branches: civil, mechanical, electrical, CS',           '⚙️', 'engineering'),
  ('College Life',  'Campus, hostel, events, and general student life',          '🏫', 'general'),
  ('Projects',      'Share ideas, find teammates, show your work',               '🚀', 'projects'),
  ('Hackathons',    'Find teammates, share ideas, win together',                 '🏆', 'events'),
  ('General',       'Anything and everything student-related',                   '💬', 'general');

-- Create a #general channel for each community
INSERT INTO public.channels (community_id, name, description)
SELECT id, 'general', 'General discussion for ' || name
FROM public.communities;

-- Done! Your StudySpace database is ready.
-- Next step: copy your Supabase URL and anon key into your .env file.
