# StudySpace — Supabase Database Schema Reference

> **Full SQL to run:** See `supabase/migrations/001_initial_schema.sql`

---

## Entity-Relationship Overview

```
auth.users (Supabase managed)
    │
    └── profiles              ← one-to-one extension of auth.users
            │
            ├── tasks         ← user's personal to-do items
            │
            ├── messages      ← messages sent in community channels
            │
            ├── message_reactions ← emoji reactions on messages
            │
            ├── search_history    ← user's past search queries
            │
            └── reports           ← moderation reports filed

communities
    └── channels
            └── messages
                    └── message_reactions
```

---

## Tables

### `profiles`
Extends Supabase `auth.users`. Auto-created when a user signs up (via trigger).

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | PK — matches `auth.users.id` |
| `username` | `text` | Unique, required |
| `full_name` | `text` | Display name |
| `avatar_url` | `text` | URL to profile picture |
| `bio` | `text` | Short bio |
| `college` | `text` | College name |
| `branch` | `text` | e.g. "Computer Science" |
| `year` | `integer` | 1–6 |
| `created_at` | `timestamptz` | Auto-set |
| `updated_at` | `timestamptz` | Auto-updated via trigger |

**RLS Policies:**
- SELECT: everyone can read profiles
- UPDATE: only the owner (`auth.uid() = id`)

---

### `tasks`
Personal to-do items for each user.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | PK, auto-generated |
| `user_id` | `uuid` | FK → `profiles.id` |
| `title` | `text` | Required |
| `description` | `text` | Optional notes |
| `category` | `text` | `assignment` \| `exam` \| `project` \| `personal` \| `college` |
| `priority` | `text` | `low` \| `medium` \| `high` |
| `due_date` | `date` | Optional deadline |
| `completed` | `boolean` | Default: false |
| `created_at` | `timestamptz` | Auto-set |
| `updated_at` | `timestamptz` | Auto-updated via trigger |

**RLS Policies:** Full CRUD only for the owning user.

---

### `communities`
Top-level discussion groups (e.g. "Programming", "Mathematics").

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | PK |
| `name` | `text` | Required |
| `description` | `text` | |
| `icon` | `text` | Emoji icon |
| `category` | `text` | |
| `created_by` | `uuid` | FK → `profiles.id` |
| `created_at` | `timestamptz` | |

**RLS Policies:**
- SELECT: everyone
- INSERT: authenticated users only

---

### `channels`
Sub-channels within a community (e.g. `#general`, `#homework-help`).

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | PK |
| `community_id` | `uuid` | FK → `communities.id` |
| `name` | `text` | Required |
| `description` | `text` | |
| `created_at` | `timestamptz` | |

**RLS Policies:** SELECT: everyone.

---

### `messages`
Chat messages inside channels. **Realtime enabled.**

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | PK |
| `channel_id` | `uuid` | FK → `channels.id` |
| `user_id` | `uuid` | FK → `profiles.id` |
| `content` | `text` | Required |
| `created_at` | `timestamptz` | |
| `edited_at` | `timestamptz` | Null if not edited |

**RLS Policies:** SELECT: everyone. INSERT/UPDATE/DELETE: owner only.

---

### `message_reactions`
Emoji reactions on messages. **Realtime enabled.**

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | PK |
| `message_id` | `uuid` | FK → `messages.id` |
| `user_id` | `uuid` | FK → `profiles.id` |
| `emoji` | `text` | e.g. "👍" |
| — | UNIQUE | `(message_id, user_id, emoji)` — no duplicate reactions |

---

### `search_history`
Stores a user's past search queries for the "Recent searches" feature.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | PK |
| `user_id` | `uuid` | FK → `profiles.id` |
| `query` | `text` | The search term |
| `created_at` | `timestamptz` | |

**RLS Policies:** Full CRUD for owner only.

---

### `reports`
Moderation reports filed against messages.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | PK |
| `reporter_id` | `uuid` | FK → `profiles.id` |
| `message_id` | `uuid` | FK → `messages.id` |
| `reason` | `text` | |
| `created_at` | `timestamptz` | |

**RLS Policies:** INSERT for authenticated users only.

---

## Indexes

| Index | Table | Column(s) | Purpose |
|---|---|---|---|
| `idx_tasks_user_id` | tasks | user_id | Fast task lookup per user |
| `idx_tasks_due_date` | tasks | due_date | Sort by deadline |
| `idx_messages_channel_id` | messages | channel_id | Load channel messages |
| `idx_messages_created_at` | messages | created_at DESC | Chronological order |
| `idx_channels_community_id` | channels | community_id | Load community channels |
| `idx_search_history_user_id` | search_history | user_id | Load user history |
| `idx_message_reactions_message_id` | message_reactions | message_id | Load reactions |

---

## Triggers

| Trigger | Table | Purpose |
|---|---|---|
| `on_auth_user_created` | `auth.users` | Auto-creates a `profiles` row on signup |
| `on_profiles_updated` | `profiles` | Auto-updates `updated_at` |
| `on_tasks_updated` | `tasks` | Auto-updates `updated_at` |

---

## Seed Data (Default Communities)

The SQL migration seeds 8 default communities, each with a `#general` channel:
- 💻 Programming
- 📐 Mathematics
- ⚡ Physics
- ⚙️ Engineering
- 🏫 College Life
- 🚀 Projects
- 🏆 Hackathons
- 💬 General
