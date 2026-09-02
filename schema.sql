-- RADAR — schema v2
-- Roda esse script inteiro no SQL Editor do seu projeto Supabase.
-- Se você já tinha rodado a v1 (tabela metric_periods), essa versão
-- substitui por uma estrutura multi-cliente e multi-mídia.

create extension if not exists "pgcrypto";

drop table if exists metric_periods cascade;

-- 1. Clientes.
create table if not exists clients (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid(),
  name text not null,
  niche text,
  created_at timestamptz not null default now()
);

-- 2. Períodos — um por cliente, com os dados comerciais (funil, a partir de
--    "qualificado" pra frente, que não é dividido por mídia).
create table if not exists periods (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid(),
  client_id uuid not null references clients(id) on delete cascade,
  period_label text not null,
  period_start date not null,
  period_end date not null,
  qualified_leads numeric not null default 0,
  meetings_scheduled numeric not null default 0,
  meetings_held numeric not null default 0,
  proposals numeric not null default 0,
  sales numeric not null default 0,
  revenue numeric not null default 0,
  notes text,
  created_at timestamptz not null default now()
);

-- 3. Entradas de marketing por mídia — várias por período (uma por
--    plataforma usada naquele período).
create table if not exists marketing_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid(),
  period_id uuid not null references periods(id) on delete cascade,
  platform text not null check (platform in ('google_ads','meta_ads','tiktok_ads','chatgpt_ads','outra')),
  custom_platform_name text, -- usado só quando platform = 'outra'
  spend numeric not null default 0,
  impressions numeric not null default 0,
  clicks numeric not null default 0,
  leads numeric not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists idx_periods_client on periods(client_id, period_end desc);
create index if not exists idx_marketing_entries_period on marketing_entries(period_id);

alter table clients enable row level security;
alter table periods enable row level security;
alter table marketing_entries enable row level security;

create policy "clients: owner full access" on clients
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "periods: owner full access" on periods
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "marketing_entries: owner full access" on marketing_entries
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
