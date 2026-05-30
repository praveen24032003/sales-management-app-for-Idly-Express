create extension if not exists pgcrypto;

create schema if not exists private;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create table if not exists public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  invite_code text not null unique,
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.organization_members (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('owner', 'manager', 'employee')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (organization_id, user_id)
);

create table if not exists public.sales_entries (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_by uuid not null references auth.users(id) on delete restrict,
  entry_date date not null,
  shop_name text not null,
  order_type text not null check (order_type in ('everydaySupply', 'externalOrder')),
  delivery_slot text not null check (delivery_slot in ('morning', 'evening')),
  delivery_time text,
  prep_lead_days integer not null default 1,
  product_type text not null check (product_type in ('idly', 'sandhagai', 'idiyappam')),
  sale_type text not null check (sale_type in ('wholesale', 'retail')),
  rate_per_unit numeric(10,2) not null,
  quantity integer not null,
  cost_per_unit numeric(10,2) not null,
  payment_status text not null check (payment_status in ('paid', 'pending')),
  paid_amount numeric(10,2),
  customer_mobile text,
  notes text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.expenses (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_by uuid not null references auth.users(id) on delete restrict,
  expense_date date not null,
  category text not null check (category in ('petrol', 'food', 'maintenance', 'other')),
  amount numeric(10,2) not null,
  notes text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.supply_templates (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_by uuid not null references auth.users(id) on delete restrict,
  shop_name text not null,
  shop_mobile text,
  product_type text not null check (product_type in ('idly', 'sandhagai', 'idiyappam')),
  sale_type text not null check (sale_type in ('wholesale', 'retail')),
  quantity integer not null default 0,
  morning_quantity integer not null default 0,
  evening_quantity integer not null default 0,
  rate_per_unit numeric(10,2) not null,
  cost_per_unit numeric(10,2) not null,
  delivery_slot text not null check (delivery_slot in ('morning', 'evening')),
  delivery_time text,
  prep_lead_days integer not null default 1,
  active_weekdays integer[] not null default array[1,2,3,4,5,6,7],
  start_date date,
  end_date date,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.dispatch_leaves (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  template_id uuid not null references public.supply_templates(id) on delete cascade,
  leave_date date not null,
  delivery_slot text not null check (delivery_slot in ('morning', 'evening')),
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.contacts (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_by uuid not null references auth.users(id) on delete restrict,
  contact_type text not null check (contact_type in ('shop', 'customer')),
  name text not null,
  mobile text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create or replace function private.is_org_member(target_org uuid)
returns boolean
language sql
security definer
set search_path = public, private
as $$
  select exists (
    select 1
    from public.organization_members member
    where member.organization_id = target_org
      and member.user_id = auth.uid()
  );
$$;

create or replace function private.has_org_role(target_org uuid, allowed_roles text[])
returns boolean
language sql
security definer
set search_path = public, private
as $$
  select exists (
    select 1
    from public.organization_members member
    where member.organization_id = target_org
      and member.user_id = auth.uid()
      and member.role = any(allowed_roles)
  );
$$;

create or replace function public.create_organization_with_owner(
  org_name text,
  org_slug text,
  org_invite_code text
)
returns table (
  id uuid,
  name text,
  slug text,
  invite_code text,
  role text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  -- NOTE: do not name this variable `current_user` — that is a reserved
  -- PostgreSQL keyword that resolves to the session role (type `name`), which
  -- silently shadows any same-named PL/pgSQL variable inside SQL statements.
  -- That caused both the auth-required check to be bypassed and a uuid/name
  -- type error on the insert into organizations.created_by.
  invoker_id uuid := auth.uid();
  created_org public.organizations%rowtype;
begin
  if invoker_id is null then
    raise exception 'Authentication required';
  end if;

  if org_name is null or btrim(org_name) = '' then
    raise exception 'Organization name is required';
  end if;

  if org_slug is null or btrim(org_slug) = '' then
    raise exception 'Organization slug is required';
  end if;

  if org_invite_code is null or btrim(org_invite_code) = '' then
    raise exception 'Organization invite code is required';
  end if;

  insert into public.organizations (
    name,
    slug,
    invite_code,
    created_by
  )
  values (
    btrim(org_name),
    btrim(org_slug),
    upper(btrim(org_invite_code)),
    invoker_id
  )
  returning * into created_org;

  insert into public.organization_members (
    organization_id,
    user_id,
    role
  )
  values (
    created_org.id,
    invoker_id,
    'owner'
  )
  on conflict (organization_id, user_id) do nothing;

  return query
  select
    created_org.id,
    created_org.name,
    created_org.slug,
    created_org.invite_code,
    'owner'::text;
end;
$$;

create or replace function public.join_organization_with_invite(
  org_invite_code text
)
returns table (
  id uuid,
  name text,
  slug text,
  invite_code text,
  role text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  invoker_id uuid := auth.uid();
  matched_org public.organizations%rowtype;
begin
  if invoker_id is null then
    raise exception 'Authentication required';
  end if;

  select *
  into matched_org
  from public.organizations organization_row
  where organization_row.invite_code = upper(btrim(org_invite_code));

  if not found then
    raise exception 'Invite code not found';
  end if;

  insert into public.organization_members (
    organization_id,
    user_id,
    role
  )
  values (
    matched_org.id,
    invoker_id,
    'employee'
  )
  on conflict (organization_id, user_id) do nothing;

  return query
  select
    matched_org.id,
    matched_org.name,
    matched_org.slug,
    matched_org.invite_code,
    member.role
  from public.organization_members member
  where member.organization_id = matched_org.id
    and member.user_id = invoker_id;
end;
$$;

drop trigger if exists organizations_set_updated_at on public.organizations;
create trigger organizations_set_updated_at
before update on public.organizations
for each row execute function public.set_updated_at();

drop trigger if exists organization_members_set_updated_at on public.organization_members;
create trigger organization_members_set_updated_at
before update on public.organization_members
for each row execute function public.set_updated_at();

drop trigger if exists sales_entries_set_updated_at on public.sales_entries;
create trigger sales_entries_set_updated_at
before update on public.sales_entries
for each row execute function public.set_updated_at();

drop trigger if exists expenses_set_updated_at on public.expenses;
create trigger expenses_set_updated_at
before update on public.expenses
for each row execute function public.set_updated_at();

drop trigger if exists supply_templates_set_updated_at on public.supply_templates;
create trigger supply_templates_set_updated_at
before update on public.supply_templates
for each row execute function public.set_updated_at();

drop trigger if exists dispatch_leaves_set_updated_at on public.dispatch_leaves;
create trigger dispatch_leaves_set_updated_at
before update on public.dispatch_leaves
for each row execute function public.set_updated_at();

drop trigger if exists contacts_set_updated_at on public.contacts;
create trigger contacts_set_updated_at
before update on public.contacts
for each row execute function public.set_updated_at();

alter table public.organizations enable row level security;
alter table public.organization_members enable row level security;
alter table public.sales_entries enable row level security;
alter table public.expenses enable row level security;
alter table public.supply_templates enable row level security;
alter table public.dispatch_leaves enable row level security;
alter table public.contacts enable row level security;

drop policy if exists organizations_select_member on public.organizations;
create policy organizations_select_member on public.organizations
for select using (private.is_org_member(id));

drop policy if exists organizations_insert_creator on public.organizations;
create policy organizations_insert_creator on public.organizations
for insert with check (auth.uid() = created_by);

drop policy if exists organizations_update_owner_manager on public.organizations;
create policy organizations_update_owner_manager on public.organizations
for update using (private.has_org_role(id, array['owner', 'manager']))
with check (private.has_org_role(id, array['owner', 'manager']));

drop policy if exists organization_members_select_member on public.organization_members;
create policy organization_members_select_member on public.organization_members
for select using (private.is_org_member(organization_id));

drop policy if exists organization_members_insert_self_or_owner on public.organization_members;
create policy organization_members_insert_owner on public.organization_members
for insert with check (private.has_org_role(organization_id, array['owner']));

drop policy if exists organization_members_update_owner on public.organization_members;
create policy organization_members_update_owner on public.organization_members
for update using (private.has_org_role(organization_id, array['owner']))
with check (private.has_org_role(organization_id, array['owner']));

drop policy if exists organization_members_delete_owner on public.organization_members;
create policy organization_members_delete_owner on public.organization_members
for delete using (private.has_org_role(organization_id, array['owner']));

drop policy if exists sales_entries_member_access on public.sales_entries;
create policy sales_entries_member_access on public.sales_entries
for all using (private.is_org_member(organization_id))
with check (private.is_org_member(organization_id));

drop policy if exists expenses_member_access on public.expenses;
create policy expenses_member_access on public.expenses
for all using (private.is_org_member(organization_id))
with check (private.is_org_member(organization_id));

drop policy if exists supply_templates_member_access on public.supply_templates;
create policy supply_templates_member_access on public.supply_templates
for all using (private.is_org_member(organization_id))
with check (private.is_org_member(organization_id));

drop policy if exists dispatch_leaves_member_access on public.dispatch_leaves;
create policy dispatch_leaves_member_access on public.dispatch_leaves
for all using (private.is_org_member(organization_id))
with check (private.is_org_member(organization_id));

drop policy if exists contacts_member_access on public.contacts;
create policy contacts_member_access on public.contacts
for all using (private.is_org_member(organization_id))
with check (private.is_org_member(organization_id));

revoke all on schema private from public;
grant usage on schema private to authenticated, anon;

revoke all on function private.is_org_member(uuid) from public;
grant execute on function private.is_org_member(uuid) to authenticated, anon;

revoke all on function private.has_org_role(uuid, text[]) from public;
grant execute on function private.has_org_role(uuid, text[]) to authenticated, anon;

revoke all on function public.create_organization_with_owner(text, text, text) from public;
grant execute on function public.create_organization_with_owner(text, text, text) to authenticated;

revoke all on function public.join_organization_with_invite(text) from public;
grant execute on function public.join_organization_with_invite(text) to authenticated;

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'organizations',
    'organization_members',
    'sales_entries',
    'expenses',
    'supply_templates',
    'dispatch_leaves',
    'contacts'
  ]
  loop
    if not exists (
      select 1
      from pg_publication_rel publication_rel
      join pg_publication publication on publication.oid = publication_rel.prpubid
      join pg_class relation on relation.oid = publication_rel.prrelid
      join pg_namespace namespace on namespace.oid = relation.relnamespace
      where publication.pubname = 'supabase_realtime'
        and namespace.nspname = 'public'
        and relation.relname = table_name
    ) then
      execute format('alter publication supabase_realtime add table public.%I', table_name);
    end if;
  end loop;
end
$$;