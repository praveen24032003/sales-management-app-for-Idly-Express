# Idly Express Org Sync Change Log

## 2026-05-24

### Feature parity completion push

- added org-scoped contacts management with live sync, offline cache integration, and settings navigation
- added pending collections by shop with FIFO payment allocation across open sales rows
- replaced the simple add-sale form with a reusable sale editor that supports date, delivery slot/time, prep lead days, customer mobile, payment fields, and notes
- added sales edit and delete actions directly from the sales list

### Release hardening

- added widget tests for the sale editor submission flow and pending collections payment flow
- updated Android release config to use the production package id instead of the generated example id
- added release-signing fallback logic so internal APK validation still works without a configured keystore
- added an enforced production-signing flag and handoff docs so public builds fail fast without a real keystore
- moved Android internet permission into the main manifest so release builds can reach Supabase
- corrected Supabase rollout doc setup values and linked a strict go-live checklist
- fixed web cache record decoding so cached web reads return decoded payload maps
- added targeted controller tests for auth error mapping, organization restore/join selection, and offline sales queue replay
- expanded controller coverage to include organization create/select and offline expense queue replay
- expanded auth coverage to include signup validation and rate-limit messaging, plus queued contact/template merge behavior against remote snapshots
- added confirmation-oriented auth messaging coverage and a second cross-entity merge-conflict test for queued contact delete plus template upsert behavior
- updated README to reflect the real v1 feature surface and release-build steps

## 2026-05-23

### Initial scaffold

- created a separate Flutter rebuild project: `idly_express_org_sync`
- added Supabase, routing, local cache, state, and config dependencies
- added `.env.example` placeholders for Supabase configuration
- documented the target org-based, realtime, offline-capable architecture
- established this running change log for future updates
- replaced the generated counter widget test with an app-shell smoke test

### Auth and organization shell

- added Supabase readiness handling so the app can compile before real backend keys are supplied
- added authenticated session controller for sign-in, sign-up, sign-out, and active organization selection
- added organization create and join flows using `organizations` and `organization_members`
- added initial workspace shell with overview, sales, dispatch, reports, and settings navigation
- ported core domain model definitions from the current app into the new rebuild structure
- documented the expected Supabase schema and a feature migration map
- replaced deprecated theme radio controls with a persisted segmented selector for system, light, and dark mode

### Backend handoff artifacts

- added `supabase/schema.sql` with organizations, membership, business tables, triggers, RLS, and realtime publication setup
- updated project README with real setup steps for local env values and Supabase schema application
- ignored local `.env` so Supabase secrets can be stored without committing them
- aligned the smoke test with the current setup-gate behavior when Supabase env values are still placeholders

### Supabase connection handoff

- attempted MCP access to hosted project `lpmzewmkiovsdhyskygy` and hit a permission error, so remote inspection and migration apply are still blocked in this session
- created a local `.env` file with the derived project URL prefilled so only the real anon key still needs to be added locally

### Supabase project targeting update

- updated local `.env` to point to hosted project `badbaheizpkflwyclizf`
- added [docs/SUPABASE_ROLLOUT.md](./SUPABASE_ROLLOUT.md) with the exact SQL editor rollout order for the new live Supabase project
- updated README setup notes to reference the active hosted project and the rollout guide

### First live hosted data slice

- replaced workspace placeholders with live org-scoped sales and expense tabs backed by Supabase streams
- added repositories and a workspace data controller for hosted `sales_entries` and `expenses`
- added overview metrics for today sales, today expenses, outstanding amount, and profit
- added simple add-sale and add-expense forms that write directly to the hosted Supabase project for the active organization

### Templates, dispatch, and offline queue

- added hosted supply template and dispatch leave model mapping, repositories, and UI screens
- replaced the dispatch placeholder with live template management and an org-scoped dispatch planner
- added a local SQLite cache plus queued write replay for sales, expenses, templates, and dispatch leaves
- merged remote snapshots with queued optimistic writes so offline-created records remain visible until reconnect sync succeeds
- hardened Supabase bootstrap to treat the placeholder anon key as unavailable instead of attempting a broken initialization

### Web fallback and auth messaging

- added a web-safe in-memory fallback for the workspace cache and sync queue so browser sessions do not depend on `sqflite`
- replaced raw Supabase auth exception strings with clearer user-facing auth messages such as email confirmation guidance
- added a manual organization refresh action so users can pull newly granted memberships without signing out