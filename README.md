# StudySpace 📚

> **One workspace. Less switching. More learning.**

An all-in-one student productivity platform built with **Flutter + Supabase**.

## Features

| Feature | Description |
|---|---|
| 🤖 AI Assistant | Ask questions, get explanations, generate study plans |
| ✅ To-Do List | Manage assignments, exams, and tasks with priorities |
| 🔍 Smart Search | Discover free educational resources |
| 💬 Community | Discord-style discussion channels for students |
| 🧮 Calculator | Scientific calculator — works offline |
| 📄 PDF Tools | Convert and process PDF files |
| 👤 Profile | Personalize your student profile |

## Tech Stack

- **Frontend:** Flutter (Dart) — Android, iOS, Web/PWA
- **Backend:** Supabase (PostgreSQL, Auth, Realtime, Storage)
- **AI:** Google Gemini API
- **State:** Provider
- **Navigation:** go_router

## Getting Started

### 1. Clone the repo
```bash
git clone https://github.com/Aryan15-r/student-workspace.git
cd student-workspace
```

### 2. Set up environment variables
```bash
cp .env.example .env
# Edit .env and add your Supabase URL, anon key, and Gemini API key
```

### 3. Set up Supabase
1. Create a free project at [supabase.com](https://supabase.com)
2. Go to **SQL Editor** in your Supabase dashboard
3. Paste and run `supabase/migrations/001_initial_schema.sql`
4. Copy your **Project URL** and **anon key** into `.env`

### 4. Install dependencies
```bash
flutter pub get
```

### 5. Run the app
```bash
# Android / iOS
flutter run

# Web (Chrome)
flutter run -d chrome

# Web (all devices on network)
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

## Database Schema

See [`docs/schema.md`](docs/schema.md) for the full schema reference.

## Project Structure

```
lib/
├── main.dart              # Entry point
├── app/                   # App-level config (theme, router)
├── core/                  # Shared utilities and widgets
├── features/              # One folder per feature
│   ├── auth/
│   ├── dashboard/
│   ├── todo/
│   ├── ai_assistant/
│   ├── search/
│   ├── community/
│   ├── calculator/
│   ├── pdf_tools/
│   └── profile/
└── shared/                # Cross-feature widgets
```

## Team

Built by B.Tech CS students for a hackathon.

## License

MIT
