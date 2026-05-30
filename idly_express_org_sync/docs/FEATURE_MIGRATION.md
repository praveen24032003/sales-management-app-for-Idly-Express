# Feature Migration Map

## Existing project reference

The current app capabilities being carried forward are:

- sales entries with payment tracking
- expense tracking
- morning and evening supply templates
- dispatch planner with leave handling
- reports and profit views
- contact management
- persisted theme selection

## Rebuild direction

### New capability added first

- authenticated users
- organization-scoped membership
- realtime cross-device updates per organization
- strict data separation between organizations

### Migration order

1. auth + organization boundary
2. sales + expenses repositories
3. templates + dispatch planner
4. offline queue + cache across hosted flows
5. reports + profit views
6. contacts + settings polish

## Notes

- the old Firebase anonymous sync approach is replaced with explicit user identity
- local-first resilience remains in scope, but the security boundary is now the organization
- each future migrated screen should read and write with `organization_id` attached