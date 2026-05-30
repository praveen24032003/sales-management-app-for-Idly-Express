# CLAUDE.md

This file is the project-specific handoff for Claude Code when working inside `idly_express_org_sync`.

## Project Summary

Idly Express Org Sync is the active Flutter rebuild of the sales-management app. It adds:

- email/password auth
- organization create, join, and selection
- offline-first workspace data with queued write replay
- Supabase-backed sync and realtime listeners
- Android release signing flow for public distribution

The old app in the workspace root is reference code only.

## Current State

These items are already complete locally:

- `flutter analyze`
- `flutter test`
- local web run verified with `flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080`
- signed APK build with enforced release signing
- signed AAB build with enforced release signing
- physical Android device install of the signed APK
- redesigned light auth and organization flow with clearer signup, verification, and workspace steps
- mobile auth callback handling for email verification via `com.idlyexpress.salesmanager://login-callback/`

Primary remaining release work:

- complete live Supabase rollout checks
- complete manual UAT on the physical device
- secure signing secrets outside the repo

## Important Paths

- app source: `lib/`
- tests: `test/`
- release checklist: `docs/GO_LIVE_CHECKLIST.md`
- signing guide: `docs/ANDROID_RELEASE_SIGNING.md`
- release review: `docs/V1_RELEASE_REVIEW.md`
- Supabase rollout: `docs/SUPABASE_ROLLOUT.md`
- signed APK: `build/app/outputs/flutter-apk/app-release.apk`
- signed AAB: `build/app/outputs/bundle/release/app-release.aab`

## Commands

Run from the project root unless noted.

```bash
flutter pub get
flutter analyze
flutter test
flutter run
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080
```

Signed Android release builds run from `android/`:

```bash
./gradlew assembleRelease -PidlyRequireReleaseSigning=true --no-daemon
./gradlew bundleRelease -PidlyRequireReleaseSigning=true --no-daemon
```

## Architecture Notes

Main control points for release-risk work:

- `lib/src/features/app_shell/application/app_session_controller.dart`
- `lib/src/features/auth/data/auth_repository.dart`
- `lib/src/features/auth/presentation/auth_screen.dart`
- `lib/src/features/organization/presentation/organization_gate_screen.dart`
- `lib/src/features/workspace/application/workspace_data_controller.dart`
- `lib/src/data/local/local_workspace_store.dart`

Tests with the most release-focused coverage:

- `test/session_and_queue_test.dart`
- `test/auth_screen_widget_test.dart`
- `test/sales_and_payments_widget_test.dart`

## Auth And Redirect Notes

- Supabase email/password signup may return `session == null` when Confirm email is enabled. This app now persists the requested organization name and finishes organization creation after the verified session becomes available.
- Mobile verification redirect depends on Supabase Auth URL Configuration allowing `com.idlyexpress.salesmanager://login-callback/`.
- Web verification is useful for UI checks, but the mobile deep-link callback behavior must still be validated on Android because web and mobile use different redirect targets.

## How To Work In This Repo

1. Stay inside `idly_express_org_sync/` unless the prompt explicitly targets the legacy app.
2. Validate changes with the narrowest useful command first.
3. Keep release docs in sync with reality. Do not mark signing as pending if the signed build already succeeded.
4. Treat `android/key.properties` and keystore files as local secrets.
5. Use `docs/GO_LIVE_CHECKLIST.md` as the source of truth for remaining launch work.
6. When auth or signup changes are involved, verify both `flutter test` and a local web run, then separately confirm the Android deep-link redirect on device.
