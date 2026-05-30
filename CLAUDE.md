# CLAUDE.md

This workspace contains two Flutter apps. Claude Code should treat `idly_express_org_sync/` as the active shipping app and the workspace root app as legacy reference code unless the prompt explicitly says otherwise.

## Active Project

**Primary target:** `idly_express_org_sync/`

- Flutter rebuild of Idly Express with login, organization scoping, offline queue replay, and Supabase sync.
- Current Android package id: `com.idlyexpress.salesmanager`.
- Mobile auth email verification now uses the app callback scheme `com.idlyexpress.salesmanager://login-callback/`.
- Signed release APK and AAB have already been produced successfully.
- The signed release APK has also been installed on a connected physical Android device.

**Legacy reference:** workspace root app (`lib/`, `android/`, `ios/`, etc.)

- Keep this code untouched unless the user explicitly asks to work on the old app.

## Start Here

1. Prefer reading `idly_express_org_sync/CLAUDE.md` first for project-specific guidance.
2. Use `idly_express_org_sync/README.md` for current release status and setup.
3. Use `idly_express_org_sync/docs/GO_LIVE_CHECKLIST.md` for launch gating.

## Working Commands

Run commands from `idly_express_org_sync/` unless a doc says otherwise.

```bash
# install deps
flutter pub get

# analyze and test
flutter analyze
flutter test

# run on device/emulator
flutter run

# run on web for local verification
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080

# build signed release artifacts from android/
cd android
./gradlew assembleRelease -PidlyRequireReleaseSigning=true --no-daemon
./gradlew bundleRelease -PidlyRequireReleaseSigning=true --no-daemon
```

## Current Release State

- Signed APK path: `idly_express_org_sync/build/app/outputs/flutter-apk/app-release.apk`
- Signed AAB path: `idly_express_org_sync/build/app/outputs/bundle/release/app-release.aab`
- Signing config lives in `idly_express_org_sync/android/key.properties` and uses `PKCS12`.
- Local web verification runs at `http://127.0.0.1:8080` with `flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080`.
- Signup now keeps the organization name pending until Supabase returns a session after email verification.
- Supabase Auth must allow `com.idlyexpress.salesmanager://login-callback/` in URL Configuration for mobile email verification to return to the app instead of `localhost`.
- Remaining launch work is primarily live Supabase rollout verification and device-level UAT, not missing core product screens.

## Guardrails

- Do not commit `android/key.properties`, `*.jks`, or other signing secrets.
- Do not reopen broad parity work unless the user requests it; the rebuild already covers the core v1 business flows.
- When editing docs, keep the rebuild app status current and avoid describing the signed build as still pending.
