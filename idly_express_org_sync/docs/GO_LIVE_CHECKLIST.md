# Go-Live Checklist

Use this checklist as the release gate for v1. Do not treat the app as ready for public distribution until every item below is complete.

## 1. Code and build gate

- [x] `flutter analyze`
- [x] `flutter test`
- [x] `flutter build apk --release`
- [x] production signing enforced with `-PidlyRequireReleaseSigning=true`
- [x] final release artifact stored from a real keystore-backed build

## 2. Android release gate

- [x] copy [../android/key.properties.example](../android/key.properties.example) to `android/key.properties`
- [x] point `storeFile` to the real upload keystore path
- [x] confirm `keyAlias`, `keyPassword`, and `storePassword` are correct
- [x] run `./gradlew assembleRelease -PidlyRequireReleaseSigning=true --no-daemon` from `android`
- [x] run `./gradlew bundleRelease -PidlyRequireReleaseSigning=true --no-daemon` from `android` for the store-upload artifact
- [x] archive or retain the signed APK or AAB together with the exact version number `1.0.0+1`
- [x] install the signed release APK on a physical Android device

## 3. Supabase rollout gate

- [ ] rerun [../supabase/schema.sql](../supabase/schema.sql) in the hosted project SQL Editor
- [ ] confirm tables exist: `organizations`, `organization_members`, `sales_entries`, `expenses`, `supply_templates`, `dispatch_leaves`, `contacts`
- [ ] confirm RPCs exist: `create_organization_with_owner`, `join_organization_with_invite`
- [ ] confirm Data API exposure or explicit grants for `authenticated` on all public business tables
- [ ] confirm RLS is enabled on every public business table
- [ ] confirm realtime publication includes all business tables
- [ ] enable leaked password protection in Supabase Auth
- [ ] verify email/password auth settings match the intended launch policy

Full rollout reference: [SUPABASE_ROLLOUT.md](./SUPABASE_ROLLOUT.md)

## 4. Runtime configuration gate

- [ ] verify local `SUPABASE_URL` points to `https://badbaheizpkflwyclizf.supabase.co`
- [ ] verify local `SUPABASE_ANON_KEY` is the intended hosted-project public key
- [ ] verify the release build launches without the setup gate screen
- [ ] confirm release build can reach Supabase over network on a physical Android device

## 5. Manual UAT gate

- [ ] sign up with a fresh user
- [ ] sign in with an existing user
- [ ] create an organization
- [ ] copy and use an invite code from a second user
- [ ] add a sale with pending payment fields
- [ ] edit an existing sale
- [ ] delete a sale
- [ ] record a pending-collections payment and confirm remaining balance updates correctly
- [ ] add an expense
- [ ] create and edit a contact
- [ ] verify insights / profit screens populate correctly
- [ ] verify offline create/edit flows replay after reconnect

## 6. Known release blockers to close

- [ ] deeper coverage is still missing for end-to-end confirmation flows against the live backend and broader queue conflict combinations beyond the current controller checks
- [x] debug-signing fallback is no longer being used for the current public-release artifacts

## Ship decision

Public release is allowed only when every unchecked box above is complete and the final APK is produced from an enforced, real-keystore build.