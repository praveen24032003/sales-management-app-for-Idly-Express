# V1 Release Review

This review focuses only on release risks, behavioral regressions, missing hardening, and missing tests that matter for shipping the first public version.

## Findings

### 1. Closed locally: Android release signing is configured and validated

This risk was the highest release blocker earlier in the cycle, but it has now been closed locally.

Validated status:

- `android/app/build.gradle.kts` supports `-PidlyRequireReleaseSigning=true`
- enforced builds succeed from the real keystore-backed configuration
- signed APK and signed AAB exist in the project build outputs
- the signed release APK has been installed on a physical Android device

Remaining operational action:

- keep the keystore and passwords backed up outside the repo
- ensure `android/key.properties` and keystore files stay out of shared history

### 2. High: hosted Supabase rollout is still a manual launch gate

The codebase is ready to target the hosted project, but launch still depends on manual backend verification:

- rerun [../supabase/schema.sql](../supabase/schema.sql)
- verify Data API exposure or grants for all public business tables
- verify RLS and realtime publication coverage
- enable leaked password protection in Supabase Auth

Launch should be blocked until every item in [GO_LIVE_CHECKLIST.md](./GO_LIVE_CHECKLIST.md) and [SUPABASE_ROLLOUT.md](./SUPABASE_ROLLOUT.md) is complete.

### 3. Medium: release-critical flows are still under-tested

Local validation currently covers:

- analyzer clean
- targeted controller tests for auth error handling, email-confirmation guidance, signup validation/rate-limit messaging, organization restore/join/create/select, and sales plus expense offline queue replay
- targeted controller merge coverage showing queued contact upserts/template deletes and queued contact deletes/template upserts override stale remote snapshots
- passing widget tests for sale editor and payment collection
- setup-gate smoke test

Still missing targeted automated coverage for:

- confirmation-oriented end-to-end auth flows against a live backend, not just mapped controller error states
- deeper multi-entity queue replay and broader remote merge conflicts beyond the current queued contact/template controller coverage

For a first public rollout, these gaps do not block internal testing, but they remain the largest remaining confidence gap after backend rollout and production signing.

### 4. Medium: web cache decoding bug existed in the local cache path

The web cache branch in `LocalWorkspaceStore.getCachedRecords()` returned raw cached rows instead of decoded payload maps because the `map(...).toList()` result was discarded.

Status:

- fixed locally during this release review
- validated with `flutter analyze` and `flutter test`

## Verdict

The Android release candidate is now locally signed, installable, and ready for final launch validation. Public distribution is still blocked until:

1. the hosted Supabase rollout checklist is completed
2. device-level UAT is completed against the live backend
3. signing secrets are backed up and handled outside the repo safely