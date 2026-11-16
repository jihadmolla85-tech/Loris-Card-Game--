-- LORIS online foundation for Supabase.
-- Apply with: supabase db push
-- Game actions/events must be written by trusted server code only.

create extension if not exists pgcrypto;

create table if not exists public.player_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(display_name) between 2 and 24),
  avatar_id text not null default 'default',
  total_xp bigint not null default 0 check (total_xp >= 0),
  rating integer not null default 1000 check (rating >= 0),
  premium_status text not null default 'free'
    check (premium_status in ('free', 'active', 'grace_period', 'expired', 'cancelled')),
  premium_expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.loris_rooms (
  id uuid primary key default gen_random_uuid(),
  room_code text not null unique
    check (room_code ~ '^[A-Z0-9]{6}$'),
  host_user_id uuid not null references auth.users(id),
  game_mode text not null check (game_mode in ('four_players', 'six_players')),
  status text not null default 'waiting'
    check (status in ('waiting', 'in_progress', 'finished', 'cancelled')),
  revision bigint not null default 0 check (revision >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.loris_room_players (
  room_id uuid not null references public.loris_rooms(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  seat_index integer not null check (seat_index between 0 and 5),
  is_ready boolean not null default false,
  joined_at timestamptz not null default now(),
  primary key (room_id, user_id),
  unique (room_id, seat_index)
);

create table if not exists public.loris_game_events (
  id bigint generated always as identity primary key,
  room_id uuid not null references public.loris_rooms(id) on delete cascade,
  sequence bigint not null check (sequence > 0),
  event_type text not null,
  public_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (room_id, sequence)
);

-- Private hands are separated from public room/event data.
create table if not exists public.loris_private_hands (
  room_id uuid not null references public.loris_rooms(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  hand jsonb not null,
  updated_at timestamptz not null default now(),
  primary key (room_id, user_id)
);

create table if not exists public.loris_seasons (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  is_active boolean not null default false,
  check (ends_at > starts_at)
);

create table if not exists public.loris_season_results (
  season_id uuid not null references public.loris_seasons(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  rating integer not null default 0 check (rating >= 0),
  wins integer not null default 0 check (wins >= 0),
  losses integer not null default 0 check (losses >= 0),
  primary key (season_id, user_id)
);

create index if not exists loris_rooms_status_created_idx
  on public.loris_rooms(status, created_at desc);
create index if not exists loris_room_players_user_idx
  on public.loris_room_players(user_id);
create index if not exists loris_game_events_room_sequence_idx
  on public.loris_game_events(room_id, sequence);
create index if not exists loris_season_results_rating_idx
  on public.loris_season_results(season_id, rating desc);

create or replace function public.loris_is_room_member(target_room uuid)
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from public.loris_room_players p
    where p.room_id = target_room and p.user_id = auth.uid()
  );
$$;

alter table public.player_profiles enable row level security;
alter table public.loris_rooms enable row level security;
alter table public.loris_room_players enable row level security;
alter table public.loris_game_events enable row level security;
alter table public.loris_private_hands enable row level security;
alter table public.loris_seasons enable row level security;
alter table public.loris_season_results enable row level security;

drop policy if exists "profiles are readable" on public.player_profiles;
create policy "profiles are readable"
  on public.player_profiles for select to authenticated using (true);
drop policy if exists "players create own profile" on public.player_profiles;
create policy "players create own profile"
  on public.player_profiles for insert to authenticated with check (user_id = auth.uid());
drop policy if exists "players update own profile" on public.player_profiles;
create policy "players update own profile"
  on public.player_profiles for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "room members can read room" on public.loris_rooms;
create policy "room members can read room"
  on public.loris_rooms for select to authenticated
  using (public.loris_is_room_member(id));
-- Room creation and membership changes are performed by RPC functions below.
drop policy if exists "members can read seats" on public.loris_room_players;
create policy "members can read seats"
  on public.loris_room_players for select to authenticated
  using (public.loris_is_room_member(room_id));
drop policy if exists "members can read public events" on public.loris_game_events;
create policy "members can read public events"
  on public.loris_game_events for select to authenticated
  using (public.loris_is_room_member(room_id));
-- No client insert/update/delete policies for game events or private hands.
drop policy if exists "players read only their hand" on public.loris_private_hands;
create policy "players read only their hand"
  on public.loris_private_hands for select to authenticated
  using (user_id = auth.uid() and public.loris_is_room_member(room_id));
drop policy if exists "seasons are readable" on public.loris_seasons;
create policy "seasons are readable"
  on public.loris_seasons for select to authenticated using (true);
drop policy if exists "season results are readable" on public.loris_season_results;
create policy "season results are readable"
  on public.loris_season_results for select to authenticated using (true);

create or replace function public.loris_create_room(
  requested_mode text,
  requested_display_name text,
  requested_avatar_id text default 'default'
)
returns public.loris_rooms
language plpgsql security definer
set search_path = public, auth
as $$
declare
  new_room public.loris_rooms;
  new_code text;
  attempt integer := 0;
begin
  if auth.uid() is null then raise exception 'authentication_required'; end if;
  if requested_mode not in ('four_players', 'six_players') then
    raise exception 'invalid_game_mode';
  end if;
  if char_length(trim(requested_display_name)) not between 2 and 24 then
    raise exception 'invalid_display_name';
  end if;

  insert into public.player_profiles(user_id, display_name, avatar_id)
  values (auth.uid(), trim(requested_display_name), coalesce(nullif(requested_avatar_id, ''), 'default'))
  on conflict (user_id) do update
    set display_name = excluded.display_name,
        avatar_id = excluded.avatar_id,
        updated_at = now();

  loop
    new_code := upper(substr(encode(gen_random_bytes(8), 'hex'), 1, 6));
    attempt := attempt + 1;
    exit when not exists (select 1 from public.loris_rooms where room_code = new_code);
    if attempt > 10 then raise exception 'room_code_generation_failed'; end if;
  end loop;

  insert into public.loris_rooms(room_code, host_user_id, game_mode)
  values (new_code, auth.uid(), requested_mode)
  returning * into new_room;

  insert into public.loris_room_players(room_id, user_id, seat_index, is_ready)
  values (new_room.id, auth.uid(), 0, true);

  return new_room;
end;
$$;

create or replace function public.loris_join_room(
  requested_room_code text,
  requested_display_name text,
  requested_avatar_id text default 'default'
)
returns public.loris_rooms
language plpgsql security definer
set search_path = public, auth
as $$
declare
  target public.loris_rooms;
  max_players integer;
  next_seat integer;
begin
  if auth.uid() is null then raise exception 'authentication_required'; end if;
  if char_length(trim(requested_display_name)) not between 2 and 24 then
    raise exception 'invalid_display_name';
  end if;

  select * into target from public.loris_rooms
  where room_code = upper(trim(requested_room_code))
  for update;
  if not found then raise exception 'room_not_found'; end if;
  if target.status <> 'waiting' then raise exception 'room_not_joinable'; end if;

  max_players := case target.game_mode when 'four_players' then 4 else 6 end;
  if exists (select 1 from public.loris_room_players
             where room_id = target.id and user_id = auth.uid()) then
    return target;
  end if;
  select coalesce(max(seat_index) + 1, 0) into next_seat
    from public.loris_room_players where room_id = target.id;
  if next_seat >= max_players then raise exception 'room_full'; end if;

  insert into public.player_profiles(user_id, display_name, avatar_id)
  values (auth.uid(), trim(requested_display_name), coalesce(nullif(requested_avatar_id, ''), 'default'))
  on conflict (user_id) do update
    set display_name = excluded.display_name,
        avatar_id = excluded.avatar_id,
        updated_at = now();

  insert into public.loris_room_players(room_id, user_id, seat_index)
  values (target.id, auth.uid(), next_seat);

  update public.loris_rooms set revision = revision + 1, updated_at = now()
  where id = target.id returning * into target;
  return target;
end;
$$;

create or replace function public.loris_set_ready(
  requested_room_id uuid,
  requested_ready boolean
)
returns void
language plpgsql security definer
set search_path = public, auth
as $$
begin
  if auth.uid() is null then raise exception 'authentication_required'; end if;
  update public.loris_room_players
  set is_ready = requested_ready
  where room_id = requested_room_id and user_id = auth.uid();
  if not found then raise exception 'not_a_room_member'; end if;
  update public.loris_rooms set revision = revision + 1, updated_at = now()
  where id = requested_room_id and status = 'waiting';
end;
$$;

create or replace function public.loris_leave_room(requested_room_id uuid)
returns void
language plpgsql security definer
set search_path = public, auth
as $$
declare
  room_host uuid;
  replacement_host uuid;
begin
  if auth.uid() is null then raise exception 'authentication_required'; end if;
  select host_user_id into room_host from public.loris_rooms
    where id = requested_room_id for update;
  if not found then return; end if;

  delete from public.loris_room_players
    where room_id = requested_room_id and user_id = auth.uid();

  if room_host = auth.uid() then
    select user_id into replacement_host from public.loris_room_players
      where room_id = requested_room_id order by seat_index limit 1;
    if replacement_host is null then
      update public.loris_rooms set status = 'cancelled', revision = revision + 1
        where id = requested_room_id;
    else
      update public.loris_rooms set host_user_id = replacement_host,
        revision = revision + 1, updated_at = now()
        where id = requested_room_id;
    end if;
  else
    update public.loris_rooms set revision = revision + 1, updated_at = now()
      where id = requested_room_id;
  end if;
end;
$$;

revoke all on function public.loris_create_room(text, text, text) from public;
revoke all on function public.loris_join_room(text, text, text) from public;
revoke all on function public.loris_set_ready(uuid, boolean) from public;
revoke all on function public.loris_leave_room(uuid) from public;
grant execute on function public.loris_create_room(text, text, text) to authenticated;
grant execute on function public.loris_join_room(text, text, text) to authenticated;
grant execute on function public.loris_set_ready(uuid, boolean) to authenticated;
grant execute on function public.loris_leave_room(uuid) to authenticated;

-- Realtime publication: room metadata and public event stream only.
do $$
begin
  alter publication supabase_realtime add table public.loris_rooms;
exception when duplicate_object then null;
end $$;
do $$
begin
  alter publication supabase_realtime add table public.loris_room_players;
exception when duplicate_object then null;
end $$;
do $$
begin
  alter publication supabase_realtime add table public.loris_game_events;
exception when duplicate_object then null;
end $$;

-- Clients may edit only their public identity fields. XP, rating and premium
-- entitlement are server-managed and cannot be self-awarded by a client.
revoke insert, update on public.player_profiles from authenticated;
grant insert (user_id, display_name, avatar_id)
  on public.player_profiles to authenticated;
grant update (display_name, avatar_id, updated_at)
  on public.player_profiles to authenticated;
