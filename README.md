# Lingayat Matrimony

Flutter Web + Supabase matrimonial MVP for the Lingayat community.

## Features

- Email/password authentication with email verification support
- Profile creation and editing with validation
- Responsive discover/search experience
- Compatibility scoring using age, city, education, occupation, and sub-community
- Shortlist and express-interest workflows
- Profile reporting
- Private photo uploads to Supabase Storage
- Admin moderation queue with role-protected access
- Dark mode and responsive Material 3 UI

## Setup

1. Create a Supabase project.
2. Run [`supabase/schema.sql`](supabase/schema.sql) in the Supabase SQL editor.
3. Create a Storage bucket named `profile-photos`; the included policies allow authenticated users to upload to their own folder and approved profile photos to be viewed.
4. Copy `.env.example` values into your run configuration.
5. Run:

```bash
flutter pub get
flutter run -d chrome --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

For a release build:

```bash
flutter build web --release \\
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \\
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Never put a service-role key in Flutter or commit secrets. The browser app must use only the public anon key and rely on RLS.

## Make an admin

After registering, set the user's profile role in Supabase SQL editor:

```sql
update public.profiles set role = 'admin' where id = 'USER_UUID';
```

## Production checklist

Configure a custom SMTP provider, email redirect URLs, domain/CORS settings, storage retention, abuse monitoring, backups, and a privacy/consent policy before collecting real matrimonial data. The supplied seed data is intentionally absent: all visible profiles are user-created.
