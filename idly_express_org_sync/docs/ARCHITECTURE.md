# Idly Express Org Sync Architecture

## Goal

Rebuild the current Flutter sales tracker as a multi-tenant application where:

- every user signs in
- each user belongs to one or more organizations
- all business data is scoped to an organization
- data never overlaps across organizations
- updates appear on other devices without manual refresh
- local storage still supports resilience when the network is unstable

## Core Model

### Tenant boundary

- `organization`: the top-level business unit
- `organization_member`: maps users to organizations with role metadata
- every business row carries `organization_id`
- Row Level Security in Supabase must reject records from other organizations

### Business entities to preserve from the current app

- sales entries
- expenses
- supply templates
- dispatch leaves
- contacts / shop metadata
- profit and report aggregates
- theme and device preferences

## Realtime Strategy

- write operations go to Supabase first when online
- realtime channels subscribe per organization
- incoming events update local cache immediately
- UI listens to the local cache so all screens refresh consistently
- if offline, operations are queued locally and replayed when connectivity returns

## Local Queue And Cache

- local SQLite cache stores the latest merged organization view for sales, expenses, supply templates, and dispatch leaves
- queued writes are stored locally with stable client-generated ids
- on reconnect, queued writes replay against Supabase and remote streams converge the local cache back to server truth
- remote snapshots are merged with queued optimistic writes so offline-created records do not disappear while waiting to sync

## Client Layers

- `core`: config, theme, routing, shared widgets
- `features/auth`: login, signup, restore session
- `features/organization`: create org, join org, switch org, member roles
- `features/dashboard`: workspace shell for the migrated feature set
- `features/sales`, `expenses`, `templates`, `dispatch`, `reports`, `settings`: migrated business features
- `data/local`: SQLite cache and offline queue
- `data/remote`: Supabase services
- `domain`: models and repository contracts

## Initial Build Scope

Phase 1 in this scaffold establishes:

- Supabase bootstrap
- auth session handling
- organization selection / creation flow
- dashboard shell with the migrated feature map
- architecture docs and change log

## Supabase Schema Draft

The current scaffold expects these core tables:

- `organizations`: `id`, `name`, `slug`, `invite_code`, `created_by`, timestamps
- `organization_members`: `organization_id`, `user_id`, `role`, timestamps
- later business tables: `sales_entries`, `expenses`, `supply_templates`, `dispatch_leaves`, `contacts`

Each business table should include:

- `id uuid primary key`
- `organization_id uuid not null`
- `created_by uuid`
- `updated_by uuid`
- `created_at timestamptz`
- `updated_at timestamptz`

Realtime subscriptions should listen only to rows matching the currently selected `organization_id`.

The next phase ports feature-by-feature business flows from the current app into the new org-aware data model.