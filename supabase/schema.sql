-- Lingayat Matrimony Supabase schema
create extension if not exists "uuid-ossp";

create type public.profile_gender as enum ('bride', 'groom');
create type public.profile_status as enum ('pending', 'approved', 'rejected');
create type public.user_role as enum ('user', 'admin');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null check (char_length(name) between 2 and 80),
  gender public.profile_gender not null,
  age int not null check (age between 18 and 80),
  city text not null,
  education text not null default '',
  occupation text not null default '',
  sub_community text not null default 'Lingayat',
  marital_status text not null default 'Never Married',
  height_cm int not null default 160 check (height_cm between 120 and 230),
  about text not null default '' check (char_length(about) <= 2000),
  photos text[] not null default '{}',
  min_age int not null default 21 check (min_age between 18 and 80),
  max_age int not null default 45 check (max_age between 18 and 80),
  preferred_cities text[] not null default '{}',
  preferred_education text not null default 'Any',
  preferred_occupation text not null default 'Any',
  role public.user_role not null default 'user',
  status public.profile_status not null default 'pending',
  verified boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (min_age <= max_age)
);

create table public.interests (
  id uuid primary key default gen_random_uuid(),
  from_user uuid not null references public.profiles(id) on delete cascade,
  to_user uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(from_user, to_user),
  check (from_user <> to_user)
);

create table public.shortlists (
  user_id uuid not null references public.profiles(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, profile_id),
  check (user_id <> profile_id)
);

create table public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  reason text not null check (char_length(reason) between 5 and 500),
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

create or replace function public.is_admin() returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles where id = auth.uid() and role = 'admin');
$$;

create or replace function public.set_updated_at() returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;
create trigger profiles_updated_at before update on public.profiles for each row execute procedure public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.interests enable row level security;
alter table public.shortlists enable row level security;
alter table public.reports enable row level security;

create policy "users create own profile" on public.profiles for insert with check (auth.uid() = id);
create policy "users read approved or own profiles" on public.profiles for select using (status = 'approved' or auth.uid() = id or public.is_admin());
create policy "users update own profile" on public.profiles for update using (auth.uid() = id or public.is_admin()) with check (auth.uid() = id or public.is_admin());
create policy "admins delete profiles" on public.profiles for delete using (public.is_admin());

create policy "interest participants read" on public.interests for select using (auth.uid() = from_user or auth.uid() = to_user or public.is_admin());
create policy "users create interests" on public.interests for insert with check (auth.uid() = from_user);
create policy "users delete own interests" on public.interests for delete using (auth.uid() = from_user);
create policy "shortlist owner read" on public.shortlists for select using (auth.uid() = user_id);
create policy "shortlist owner write" on public.shortlists for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "reporter creates reports" on public.reports for insert with check (auth.uid() = reporter_id);
create policy "reporters and admins read reports" on public.reports for select using (auth.uid() = reporter_id or public.is_admin());
create policy "admins resolve reports" on public.reports for update using (public.is_admin());

create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, name, gender, age, city) values (new.id, coalesce(new.raw_user_meta_data->>'name', 'New member'), coalesce((new.raw_user_meta_data->>'gender')::public.profile_gender, 'bride'), 18, '');
  return new;
end; $$;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

insert into storage.buckets (id, name, public) values ('profile-photos', 'profile-photos', false) on conflict (id) do nothing;
create policy "users upload own photos" on storage.objects for insert to authenticated with check (bucket_id = 'profile-photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "users manage own photos" on storage.objects for delete to authenticated using (bucket_id = 'profile-photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "authenticated view approved photos" on storage.objects for select to authenticated using (bucket_id = 'profile-photos');
