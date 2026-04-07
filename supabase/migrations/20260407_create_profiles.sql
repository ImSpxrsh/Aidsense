-- AidSense production profile table migration
-- Run this in Supabase SQL editor (or via Supabase migrations) before deployment.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  uid uuid primary key references auth.users(id) on delete cascade,
  id uuid unique,
  "fullName" text not null default '',
  email text not null default '',
  phone text not null default '',
  favorites text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_id_matches_uid check (id is null or id = uid)
);

update public.profiles
set id = uid
where id is null;

create index if not exists profiles_email_idx on public.profiles (email);

create or replace function public.set_profiles_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
before update on public.profiles
for each row
execute function public.set_profiles_updated_at();

alter table public.profiles enable row level security;

drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own
on public.profiles
for select
to authenticated
using (auth.uid() = uid);

drop policy if exists profiles_insert_own on public.profiles;
create policy profiles_insert_own
on public.profiles
for insert
to authenticated
with check (auth.uid() = uid);

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own
on public.profiles
for update
to authenticated
using (auth.uid() = uid)
with check (auth.uid() = uid);

drop policy if exists profiles_delete_own on public.profiles;
create policy profiles_delete_own
on public.profiles
for delete
to authenticated
using (auth.uid() = uid);