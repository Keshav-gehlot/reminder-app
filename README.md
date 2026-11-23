# CyberTrack 12

CyberTrack 12 combines reminders, a 12-week planner, CTF practice, LeetCode/competitive programming, and four research workstreams in one Flutter Android app.

## Features
- Local reminders with scheduled Android notifications
- CTF, LeetCode and contest activity log
- Weekly checklist and 12-week roadmap
- Research milestone tracking for LeakTrace + ECDAT, CROSSWITNESS, Network Attack Forecasting, and Bluetooth Music Middleware
- Offline-first local cache
- Optional Supabase email OTP sign-in, per-account cloud sync, and realtime updates between Android devices/instances

## Cloud sync setup
1. Create a Supabase project.
2. Run `supabase/migrations/202611230001_cybertrack_workspace.sql` in the Supabase SQL Editor.
3. In Supabase Authentication, enable email OTP and configure your email provider.
4. Copy the Project URL and publishable key from the Supabase Connect dialog.
5. Build with:
   ```bash
   flutter build apk --release \
     --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
     --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
   ```
6. Install the same build on each Android device and sign in using the same email address. Each device has its own local notification schedule; the workspace data syncs through the shared account.

**Never put a Supabase secret/service_role key in the Android app.** Only the publishable key belongs in the client; row-level security protects account data.

## GitHub Actions APK
Push to `main` or run the **Android APK** workflow manually. The workflow builds a release-mode APK and uploads it as a downloadable Actions artifact. The build also runs without Supabase secrets in local/offline mode; add repository Actions variables `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` to enable cloud sync in the generated APK.

## Run locally
```bash
flutter pub get
flutter run
```

## Sync model
- A user's workspace is scoped by the authenticated Supabase user ID.
- Changes are cached locally and pushed when online.
- Realtime database events refresh other signed-in instances.
- Entries are merged by stable ID and per-entry `updatedAt`; delete tombstones sync deletions.
- On a same-entry concurrent edit, latest `updatedAt` wins. This is deterministic last-write-wins, not field-level collaborative editing.

## Reminder behavior
Notifications are scheduled locally on each device. Reminders themselves sync to the account workspace, but Android notifications are device-local and are re-scheduled when that device loads the workspace. Android may defer inexact alarms under battery restrictions.
