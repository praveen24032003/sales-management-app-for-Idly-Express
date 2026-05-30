# Supabase Rollout Order

Target project:

- project ref: `badbaheizpkflwyclizf`
- project name: `idly express`
- region: `ap-southeast-1`

## Before you run SQL

1. Open the SQL Editor for the target project.
2. Open [../supabase/schema.sql](../supabase/schema.sql).
3. Paste the SQL into a new query tab.
4. Confirm you are in project `badbaheizpkflwyclizf`, not another project.

## Exact rollout order

### Step 1: Base schema

Run the full contents of [../supabase/schema.sql](../supabase/schema.sql).

This creates:

- extension `pgcrypto`
- trigger helper `set_updated_at()`
- tables for organizations, organization members, sales entries, expenses, supply templates, dispatch leaves, and contacts
- membership helper functions for RLS checks
- updated-at triggers
- Row Level Security policies
- realtime publication registration

### Step 2: Verify created tables

In Table Editor or with SQL, confirm these tables exist:

- `public.organizations`
- `public.organization_members`
- `public.sales_entries`
- `public.expenses`
- `public.supply_templates`
- `public.dispatch_leaves`
- `public.contacts`

Also confirm these RPC functions exist because organization create and join now use them instead of direct table access:

- `public.create_organization_with_owner(text, text, text)`
- `public.join_organization_with_invite(text)`

### Step 3: Verify Data API exposure or grants

This app reads and writes through the Supabase Data API from the Flutter client.

Because new public tables are no longer exposed automatically on newer Supabase projects, confirm `authenticated` can access these tables through the Data API:

- `public.organizations`
- `public.organization_members`
- `public.sales_entries`
- `public.expenses`
- `public.supply_templates`
- `public.dispatch_leaves`
- `public.contacts`

If your project uses explicit exposure/grants, apply them before app testing. RLS alone is not enough if the table is not exposed.

### Step 4: Verify authentication settings

In the Supabase dashboard:

1. Go to Authentication.
2. Enable Email provider if it is not already enabled.
3. Decide whether email confirmation should be required during this build phase.

Recommended for fast internal testing:

- enable email/password sign-in
- disable mandatory email confirmation temporarily if you want immediate test logins

### Step 5: Verify RLS behavior

Check that RLS is enabled on all business tables and on:

- `organizations`
- `organization_members`

The schema file already enables RLS, so this step is a sanity check in the dashboard.

### Step 6: Verify realtime publication

In Database or Realtime settings, confirm the following tables are in `_realtime`:

- `organizations`
- `organization_members`
- `sales_entries`
- `expenses`
- `supply_templates`
- `dispatch_leaves`
- `contacts`

### Step 7: Get client credentials

From Project Settings → API:

1. Copy the project URL.
2. Copy the anon public key.

Use them in [../.env](../.env):

```env
SUPABASE_URL=https://badbaheizpkflwyclizf.supabase.co
SUPABASE_ANON_KEY=YOUR_REAL_ANON_KEY
```

### Step 8: Local app validation

Run:

```powershell
flutter analyze
flutter test
flutter run
```

Then verify this flow in the app:

1. Create a user account.
2. Create an organization.
3. Sign out and sign back in.
4. Confirm the organization is visible.
5. Copy the invite code.
6. Use a second user to join the organization.

## Recommended first production check

After auth works, the next feature slice to connect is:

1. `sales_entries`
2. `expenses`
3. realtime subscriptions scoped by `organization_id`

That order keeps the most important business data flowing first.

## Known limitation in this session

This coding session can read the project metadata through MCP, but it does not expose a remote SQL apply tool. The SQL must be run from the Supabase dashboard SQL Editor.