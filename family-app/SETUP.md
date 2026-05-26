# Family Hub — Setup Guide

## What this is
A cross-platform family organizer (Android, iOS, Windows, macOS, Linux) built with Flutter and Supabase.
Features: shared calendar, shopping/to-do lists (real-time sync), and a family photo journal.

## Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.16
- A [Supabase](https://supabase.com) account (free tier is enough for a family)

---

## 1. Set up Supabase

1. Create a new project at [supabase.com](https://supabase.com).
2. Go to **SQL Editor** → paste and run `supabase/schema.sql`.
3. Go to **Storage** → create a bucket named `journal-photos`, set it to **Public**.
4. Copy your project URL and anon key from **Project Settings → API**.

### Self-hosting (optional)
Follow the [Supabase self-hosting guide](https://supabase.com/docs/guides/self-hosting).
Use the same `schema.sql` against your self-hosted PostgreSQL instance.

---

## 2. Configure & run the app

```bash
cd family-app
flutter pub get

# Android / iOS
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Desktop (Windows / macOS / Linux)
flutter run -d windows \   # or macos / linux
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

---

## 3. First launch flow

1. **Sign up** with an email + password.
2. **Set your name and color** — this is how your family sees you on the calendar.
3. **Create your family** (give it a name) or **join** with an 8-character invite code.
4. Share the invite code (shown in Settings) with family members so they can join.

---

## 4. Building for release

### Android APK
```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

### iOS
```bash
flutter build ipa --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

### Windows / macOS
```bash
flutter build windows --release --dart-define=...
flutter build macos --release --dart-define=...
```

---

## Feature overview

| Feature | Details |
|---------|---------|
| **Calendar** | Monthly/weekly view, color-coded by family member, tap day for events |
| **Events** | Title, date/time or all-day, location, notes, custom color |
| **Lists** | Shopping or to-do, progress bar, slide to delete |
| **Real-time lists** | Items sync instantly across all family devices |
| **Journal** | Photo grid + text entries, full-screen photo viewer |
| **Responsive** | Bottom nav on phone, side rail on tablet/desktop |
| **Dark mode** | Follows system preference |

---

## Project structure

```
lib/
├── main.dart               Entry point (Supabase init)
├── app.dart                MaterialApp.router
├── core/
│   ├── theme.dart          Material 3 + warm colour palette
│   └── router.dart         go_router with StatefulShellRoute tabs
├── models/                 Plain Dart models with fromJson/toJson
├── providers/              Riverpod state (auth, calendar, lists, journal)
├── screens/
│   ├── auth/               Login · Profile setup · Family setup
│   ├── calendar/           Monthly calendar + event form
│   ├── lists/              List overview + real-time item detail
│   └── journal/            Photo grid + entry editor
└── widgets/
    └── family_avatar.dart  Colored circle with initials / photo
supabase/
└── schema.sql              Full PostgreSQL schema + RLS policies
```
