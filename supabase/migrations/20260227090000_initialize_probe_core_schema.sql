-- Probe core production-grade schema (Supabase/PostgreSQL)
-- Structural foundation only: tables, constraints, indexes, and integrity rules.

begin;

create extension if not exists pgcrypto;

-- =========================
-- Enum types
-- =========================
create type public.user_role as enum ('OWNER');
create type public.user_status as enum ('ACTIVE', 'INACTIVE', 'SUSPENDED');

create type public.vat_mode as enum ('AUTOMATIC', 'MANUAL');
create type public.seller_active_status as enum ('ACTIVE', 'INACTIVE');

create type public.credibility_level as enum ('HIGH', 'MODERATE', 'LOW_IMPROVING');

create type public.receipt_status as enum ('ACTIVE', 'INACTIVE');

create type public.staff_role as enum ('OWNER', 'SENIOR_MANAGER', 'ASSISTANT_MANAGER', 'EMPLOYEE');
create type public.staff_active_status as enum ('ACTIVE', 'INACTIVE');

create type public.dispute_status as enum ('OPEN', 'RESOLVED');

create type public.badge_type as enum ('CORPORATE', 'PREMIUM', 'FEATURED');

-- =========================
-- Foundational tables
-- =========================
create table public.users (
  id uuid primary key default gen_random_uuid(),
  email text not null unique,
  created_at timestamptz not null default now(),
  role public.user_role not null default 'OWNER',
  status public.user_status not null default 'ACTIVE'
);

create table public.sellers (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null,
  business_name text not null,
  category_primary text,
  category_secondary text,
  category_tertiary text,
  vat_mode public.vat_mode not null default 'AUTOMATIC',
  created_at timestamptz not null default now(),
  active_status public.seller_active_status not null default 'ACTIVE',
  deleted_at timestamptz,
  constraint fk_sellers_owner
    foreign key (owner_id)
    references public.users(id)
    on delete restrict
);

create table public.seller_public_profiles (
  seller_id uuid primary key,
  display_name text not null,
  logo_url text,
  location text,
  since_year integer,
  business_category_label text,
  activity_status text,
  last_system_update timestamptz not null default now(),
  constraint fk_seller_public_profiles_seller
    foreign key (seller_id)
    references public.sellers(id)
    on delete restrict,
  constraint chk_seller_public_profiles_since_year
    check (since_year is null or since_year between 1800 and extract(year from now())::integer)
);

create table public.credibility_public_state (
  seller_id uuid primary key,
  credibility_level public.credibility_level not null,
  last_evaluated_at timestamptz not null,
  constraint fk_credibility_public_state_seller
    foreign key (seller_id)
    references public.sellers(id)
    on delete restrict
);

create table public.credibility_internal_metrics (
  seller_id uuid not null,
  rolling_window_start timestamptz not null,
  dispute_ratio numeric(7,4) not null,
  resolution_rate numeric(7,4) not null,
  behavioral_flags jsonb not null default '[]'::jsonb,
  last_computed_at timestamptz not null,
  constraint pk_credibility_internal_metrics
    primary key (seller_id, rolling_window_start),
  constraint fk_credibility_internal_metrics_seller
    foreign key (seller_id)
    references public.sellers(id)
    on delete restrict,
  constraint chk_credibility_internal_metrics_dispute_ratio
    check (dispute_ratio >= 0 and dispute_ratio <= 1),
  constraint chk_credibility_internal_metrics_resolution_rate
    check (resolution_rate >= 0 and resolution_rate <= 1)
);

-- =========================
-- Staff and branch structure
-- =========================
create table public.branches (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null,
  branch_name text not null,
  created_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint fk_branches_seller
    foreign key (seller_id)
    references public.sellers(id)
    on delete restrict,
  constraint uq_branches_id_seller_id
    unique (id, seller_id)
);

create table public.staff (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null,
  branch_id uuid,
  role public.staff_role not null,
  position_label text,
  assigned_at timestamptz not null default now(),
  active_status public.staff_active_status not null default 'ACTIVE',
  deleted_at timestamptz,
  constraint fk_staff_seller
    foreign key (seller_id)
    references public.sellers(id)
    on delete restrict,
  constraint fk_staff_branch
    foreign key (branch_id, seller_id)
    references public.branches(id, seller_id)
    on delete restrict,
  constraint uq_staff_id_seller_id
    unique (id, seller_id)
);

-- =========================
-- Receipt system (immutable ledger + soft delete)
-- =========================
create table public.receipts (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null,
  branch_id uuid,
  staff_id uuid,
  reference_id text not null unique,
  subtotal_amount numeric(14,2) not null,
  vat_amount numeric(14,2) not null,
  total_amount numeric(14,2) not null,
  profit_amount numeric(14,2) not null,
  status public.receipt_status not null default 'ACTIVE',
  created_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint fk_receipts_seller
    foreign key (seller_id)
    references public.sellers(id)
    on delete restrict,
  constraint fk_receipts_branch
    foreign key (branch_id)
    references public.branches(id)
    on delete restrict,
  constraint fk_receipts_staff
    foreign key (staff_id, seller_id)
    references public.staff(id, seller_id)
    on delete restrict,
  constraint uq_receipts_id_seller_id
    unique (id, seller_id),
  constraint chk_receipts_subtotal_non_negative
    check (subtotal_amount >= 0),
  constraint chk_receipts_vat_non_negative
    check (vat_amount >= 0),
  constraint chk_receipts_total_non_negative
    check (total_amount >= 0),
  constraint chk_receipts_profit_amount_any_value
    check (profit_amount is not null),
  constraint chk_receipts_deleted_inactive_consistency
    check ((deleted_at is null) or (status = 'INACTIVE')),
  constraint chk_receipts_total_matches_components
    check (total_amount = subtotal_amount + vat_amount)
);

create table public.receipt_items (
  id uuid primary key default gen_random_uuid(),
  receipt_id uuid not null,
  item_name text not null,
  category text,
  selling_price numeric(14,2) not null,
  cost_price_per_item numeric(14,2) not null,
  quantity integer not null,
  vat_applied boolean not null default false,
  constraint fk_receipt_items_receipt
    foreign key (receipt_id)
    references public.receipts(id)
    on delete restrict,
  constraint chk_receipt_items_selling_price_non_negative
    check (selling_price >= 0),
  constraint chk_receipt_items_cost_price_non_negative
    check (cost_price_per_item >= 0),
  constraint chk_receipt_items_quantity_positive
    check (quantity > 0)
);

create or replace function public.block_receipt_delete()
returns trigger
language plpgsql
as $$
begin
  raise exception 'Hard deletion is disabled for receipts. Use status/deleted_at soft-delete semantics.';
end;
$$;

create trigger trg_block_receipt_delete
before delete on public.receipts
for each row
execute function public.block_receipt_delete();

-- =========================
-- Dispute system
-- =========================
create table public.disputes (
  id uuid primary key default gen_random_uuid(),
  receipt_id uuid not null unique,
  seller_id uuid not null,
  device_hash text not null,
  reason text not null,
  status public.dispute_status not null default 'OPEN',
  created_at timestamptz not null default now(),
  resolved_at timestamptz,
  constraint fk_disputes_receipt_seller
    foreign key (receipt_id, seller_id)
    references public.receipts(id, seller_id)
    on delete restrict,
  constraint fk_disputes_seller
    foreign key (seller_id)
    references public.sellers(id)
    on delete restrict,
  constraint chk_disputes_resolution_consistency
    check (
      (status = 'OPEN' and resolved_at is null)
      or (status = 'RESOLVED' and resolved_at is not null)
    )
);

-- =========================
-- Badge system
-- =========================
create table public.seller_badges (
  seller_id uuid primary key,
  badge_type public.badge_type not null,
  assigned_at timestamptz not null default now(),
  assigned_by text not null,
  constraint fk_seller_badges_seller
    foreign key (seller_id)
    references public.sellers(id)
    on delete restrict
);

-- =========================
-- Indexes for performance and auditing
-- =========================
create index idx_users_status on public.users(status);

create index idx_sellers_owner_id on public.sellers(owner_id);
create index idx_sellers_active_status on public.sellers(active_status);
create index idx_sellers_created_at on public.sellers(created_at desc);

create index idx_credibility_public_state_level on public.credibility_public_state(credibility_level);
create index idx_credibility_internal_metrics_last_computed_at on public.credibility_internal_metrics(last_computed_at desc);

create index idx_branches_seller_id on public.branches(seller_id);

create index idx_staff_seller_id on public.staff(seller_id);
create index idx_staff_branch_id on public.staff(branch_id);
create index idx_staff_role on public.staff(role);
create index idx_staff_active_status on public.staff(active_status);

create index idx_receipts_seller_id_created_at on public.receipts(seller_id, created_at desc);
create index idx_receipts_branch_id_created_at on public.receipts(branch_id, created_at desc);
create index idx_receipts_staff_id_created_at on public.receipts(staff_id, created_at desc);
create index idx_receipts_status on public.receipts(status);
create index idx_receipts_deleted_at on public.receipts(deleted_at);

create index idx_receipt_items_receipt_id on public.receipt_items(receipt_id);
create index idx_receipt_items_category on public.receipt_items(category);

create index idx_disputes_seller_id_created_at on public.disputes(seller_id, created_at desc);
create index idx_disputes_status on public.disputes(status);
create index idx_disputes_device_hash on public.disputes(device_hash);

create index idx_seller_badges_badge_type on public.seller_badges(badge_type);

commit;
