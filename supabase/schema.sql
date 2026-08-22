-- Broadcast Automator schema for Supabase
-- Run this in the Supabase Dashboard -> SQL Editor.

create extension if not exists pgcrypto;

-- ---------- campaigns ----------
create table if not exists public.campaigns (
  id uuid primary key default gen_random_uuid(),
  name text not null default '',
  contact_count integer not null default 0,
  created_at text,
  status text,
  message_body text,
  delay_seconds integer,
  randomize_delay boolean,
  skip_invalid boolean,
  auto_retry boolean,
  current_index integer
);

-- ---------- contacts ----------
create table if not exists public.contacts (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid references public.campaigns (id) on delete cascade,
  name text,
  phone text,
  status text
);

-- ---------- attachments ----------
create table if not exists public.attachments (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid references public.campaigns (id) on delete cascade,
  source_url text,
  type text
);

-- ---------- Realtime ----------
alter table public.campaigns replica identity full;
alter table public.contacts replica identity full;
alter table public.attachments replica identity full;

alter publication supabase_realtime add table public.campaigns;
alter publication supabase_realtime add table public.contacts;
alter publication supabase_realtime add table public.attachments;

-- ---------- Row Level Security: open (anon) ----------
alter table public.campaigns enable row level security;
alter table public.contacts enable row level security;
alter table public.attachments enable row level security;

drop policy if exists "open select" on public.campaigns;
create policy "open select" on public.campaigns for select using (true);
drop policy if exists "open insert" on public.campaigns;
create policy "open insert" on public.campaigns for insert with check (true);
drop policy if exists "open update" on public.campaigns;
create policy "open update" on public.campaigns for update using (true) with check (true);
drop policy if exists "open delete" on public.campaigns;
create policy "open delete" on public.campaigns for delete using (true);

drop policy if exists "open select" on public.contacts;
create policy "open select" on public.contacts for select using (true);
drop policy if exists "open insert" on public.contacts;
create policy "open insert" on public.contacts for insert with check (true);
drop policy if exists "open update" on public.contacts;
create policy "open update" on public.contacts for update using (true) with check (true);
drop policy if exists "open delete" on public.contacts;
create policy "open delete" on public.contacts for delete using (true);

drop policy if exists "open select" on public.attachments;
create policy "open select" on public.attachments for select using (true);
drop policy if exists "open insert" on public.attachments;
create policy "open insert" on public.attachments for insert with check (true);
drop policy if exists "open update" on public.attachments;
create policy "open update" on public.attachments for update using (true) with check (true);
drop policy if exists "open delete" on public.attachments;
create policy "open delete" on public.attachments for delete using (true);
