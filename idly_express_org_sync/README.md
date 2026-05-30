# Idly Express Org Sync

Flutter rebuild of the existing Idly Express sales app with explicit login, organization-based data boundaries, and Supabase realtime sync.

## Current status

The rebuild now includes the core v1 business flows:

- sign in and sign up flow
- organization create, join, and selection flow
- persisted theme mode setting
- org-aware workspace shell
- sales add, edit, delete, and payment-state tracking
- pending collections grouped by shop with payment collection flow
- expenses, templates, dispatch planning, contacts, insights, and profit views
- offline queue replay for core write operations
- Supabase schema draft in [supabase/schema.sql](supabase/schema.sql)
- rollout steps for the live hosted project in [docs/SUPABASE_ROLLOUT.md](docs/SUPABASE_ROLLOUT.md)
- strict production release checklist in [docs/GO_LIVE_CHECKLIST.md](docs/GO_LIVE_CHECKLIST.md)
- Android signing handoff in [docs/ANDROID_RELEASE_SIGNING.md](docs/ANDROID_RELEASE_SIGNING.md)
- running design notes in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) and [docs/CHANGE_LOG.md](docs/CHANGE_LOG.md)
- signed release APK and AAB successfully built from a real keystore-backed build
- signed release APK successfully installed on a physical Android device

Remaining release work is primarily live backend verification, manual UAT, and secret handling, not missing core business screens.

## Setup

1. Create a local `.env` file from `.env.example`.
2. Use the active hosted project URL `https://badbaheizpkflwyclizf.supabase.co`.
3. Fill in the real `SUPABASE_ANON_KEY`.
4. Apply the SQL in [supabase/schema.sql](supabase/schema.sql) using the rollout order in [docs/SUPABASE_ROLLOUT.md](docs/SUPABASE_ROLLOUT.md).
5. Run `flutter pub get`.
6. Run `flutter run`.

## Commands

- `flutter analyze`
- `flutter test`
- `flutter run`
- `flutter build apk --release`

Signed release builds from `android/`:

- `./gradlew assembleRelease -PidlyRequireReleaseSigning=true --no-daemon`
- `./gradlew bundleRelease -PidlyRequireReleaseSigning=true --no-daemon`

## Android release notes

- The Android app now uses the production package id `com.idlyexpress.salesmanager`.
- If `android/key.properties` is present with release keystore values, release builds use that signing config.
- If no release keystore is configured yet, release builds fall back to debug signing so internal APK validation can still proceed.
- For production enforcement, run Gradle with `-PidlyRequireReleaseSigning=true` so the build fails if release signing is not configured.
- The release signing config now also sets `storeType=PKCS12` explicitly.
- Network access is declared in the main Android manifest so Supabase works in release builds.
- Current signed artifacts are:
	- `build/app/outputs/flutter-apk/app-release.apk`
	- `build/app/outputs/bundle/release/app-release.aab`

## Notes

- Hosted project access is confirmed for `badbaheizpkflwyclizf`, but this session still does not expose a remote SQL apply tool, so schema rollout must be done in Supabase SQL Editor.
- The existing app remains untouched in the sibling project root. This rebuild lives in `idly_express_org_sync`.
- Before shipping to real users, re-run the hosted schema, verify Data API exposure or grants, enable leaked password protection in Supabase Auth, and complete physical-device UAT against the live backend.

## Claude Code handoff

- Workspace-level guidance: [../CLAUDE.md](../CLAUDE.md)
- Project-level guidance: [CLAUDE.md](CLAUDE.md)
- Treat `idly_express_org_sync` as the active app and the workspace root app as legacy reference.
