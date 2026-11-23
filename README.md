# CyberTrack 12

CyberTrack 12 is a Flutter Android app combining reminders, a 12-week learning plan, CTF practice, LeetCode/competitive programming and research tracking.

## App modules
- **Home** — overall progress, task counts, research projects and upcoming reminders.
- **Planner** — 12 weeks of checklist tasks for LeetCode, individual/team CTF, all four research workstreams and weekly reviews.
- **Practice** — activity history for CTF, LeetCode, contests and research notes.
- **Reminders** — date/time reminders with local Android notifications.
- **Research** — milestone completion and research-session notes for:
  - LeakTrace + ECDAT
  - CROSSWITNESS
  - Network Attack Forecasting
  - Bluetooth Music Middleware

## Offline and multi-device sync

The app is local-first. It saves a local cache and can be used while offline. For cloud sync, install a build configured with Supabase, then sign in using the same email address on each Android device or app instance.

- Account data is scoped by Supabase Auth user ID.
- Supabase Row Level Security restricts each account to its own workspace.
- Realtime Postgres events refresh other signed-in instances.
- Local writes are sent to the cloud when connectivity is available; the app retries on resume or manual sync.
- Records merge by stable item ID and `updatedAt`. For concurrent edits to the same record, latest timestamp wins. This is last-write-wins, not field-level collaborative editing.
- Deletes use tombstones so a deleted item does not reappear during a later sync.

**Reminder detail:** reminder records sync between devices. Android notification schedules are device-local, so each installed device schedules the reminders when it loads/syncs the workspace.

## Configure Supabase

1. Create or select a Supabase project.
2. Run `supabase/migrations/202611230001_cybertrack_workspace.sql` in the Supabase SQL Editor.
3. In Supabase Authentication, enable the Email provider and email OTP.
4. Set the email OTP template to include the token placeholder `{{ .Token }}`, because the app asks the user to enter the one-time code.
5. Ensure the `public` schema is exposed through the Supabase Data API and that Realtime is enabled for `public.workspaces`. The migration adds the table to `supabase_realtime` when that publication exists.
6. Copy the Project URL and the **publishable** key from the project's Connect dialog.
7. In GitHub, open **Settings → Secrets and variables → Actions → Variables** and add:
   - `SUPABASE_URL`
   - `SUPABASE_PUBLISHABLE_KEY`
8. Push to `main` or run the **Android APK** workflow manually. Install the generated APK on each device and sign in with the same email.

Never place a Supabase `service_role` or secret key in the Android app or GitHub Actions variables used by this client build. The Android app only needs the project URL and publishable key; access is controlled by Auth and RLS.

## Build locally

Flutter 3.50 stable is used by CI.

```bash
flutter pub get
flutter create --platforms=android --org com.keshavgehlot --project-name cybertrack12 .
flutter run
```

To build a release APK locally:

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
```

Leave the Dart defines empty or unset for local-only mode.

## GitHub Actions APK

Workflow: `.github/workflows/android-apk.yml`

It runs on pushes to `main` and on manual dispatch. It:
1. Generates the Android platform folder if it is missing.
2. Configures Android notification receivers and desugaring.
3. Runs `flutter pub get` and `flutter analyze`.
4. Builds `app-release.apk`.
5. Uploads the APK as the `cybertrack12-android-apk` artifact for 30 days.

Find the build under **GitHub → Actions → Android APK → latest successful run → Artifacts**.

## Database and security

The migration creates one JSON workspace row per authenticated user. The sync RPC is `public.sync_workspace(jsonb)`; it is `SECURITY INVOKER`, checks `auth.uid()`, and only grants execution to the authenticated role. The `workspaces` table has RLS policies for the owning user.

The app is designed for task, reminder and research tracking. Do not store passwords, API tokens, private keys or sensitive evidence in its notes.
