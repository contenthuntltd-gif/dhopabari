# Dhopa Bari — Supabase Auth setup (customer-app)

The customer-app now authenticates entirely through **Supabase Auth**
(Firebase + the Node backend are no longer used by the app). Two sign-in
methods: **Continue with Google** and **Phone number + SMS OTP**.

Project: `stxzqmrnezedphysmczq` → `https://stxzqmrnezedphysmczq.supabase.co`

## What the app code already does
- `lib/services/supabase_config.dart` — project URL + anon key + Google client IDs
- `lib/services/auth_service.dart` — Google, phone OTP, profile load/update
- `lib/services/google_auth_service.dart` — native Google → `signInWithIdToken`
- `lib/screens/otp_screen.dart` — 6-digit code entry
- `login_screen` / `register_screen` — phone → OTP flow

## What YOU must do (can't be done from code)

### 1. Run the DB migration
Apply `supabase/migrations/0001_auth_profiles.sql` — creates `public.profiles`,
the auto-create-on-signup trigger, and RLS. Run it via the authorized Supabase
MCP or Dashboard → SQL Editor.

### 2. Add the anon key
Dashboard → Project Settings → API → copy the **anon public** key. Either paste
it into `SupabaseConfig.anonKey`, or pass at build time:
```
flutter run --dart-define=SUPABASE_ANON_KEY=eyJ...
```

### 3. Enable Phone (SMS) auth
Dashboard → Authentication → Providers → **Phone** → enable, then plug in an SMS
provider (Twilio / MessageBird / Vonage / Textlocal). This is a **paid external
account** — sign up with the provider, then paste their credentials here.
Bangladesh numbers are sent in E.164 (`+8801XXXXXXXXX`); the app converts
local input automatically.

### 4. Enable Google auth
- Google Cloud Console → create OAuth 2.0 **Web** client → copy client ID/secret.
- Also create **Android** (needs your app's SHA-1) and **iOS** OAuth clients.
- Dashboard → Authentication → Providers → **Google** → enable, paste the Web
  client ID + secret.
- Pass the client IDs to the app:
  ```
  --dart-define=GOOGLE_WEB_CLIENT_ID=xxx.apps.googleusercontent.com
  --dart-define=GOOGLE_IOS_CLIENT_ID=yyy.apps.googleusercontent.com
  ```

### 5. `flutter pub get`
Pulls `supabase_flutter`, drops the removed Firebase plugins, and regenerates
the native plugin registrants.
