-- Out tonight: a member sets when their status ends. It is on while that time
-- is in the future, so it ends without a job or another app launch.

begin;

alter table public.profiles
  add column if not exists out_tonight_until timestamptz;

create or replace function public.limit_out_tonight()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.out_tonight_until is not null
    and new.out_tonight_until > now() + interval '24 hours'
  then
    raise exception 'Out tonight can last up to 24 hours';
  end if;
  return new;
end;
$$;

revoke all on function public.limit_out_tonight() from public, anon, authenticated;

drop trigger if exists profiles_limit_out_tonight on public.profiles;
create trigger profiles_limit_out_tonight
  before insert or update of out_tonight_until on public.profiles
  for each row execute function public.limit_out_tonight();

grant select (out_tonight_until) on table public.profiles to authenticated;

drop function if exists public.get_discovery_candidates(integer);
create function public.get_discovery_candidates(p_limit integer default 500)
returns table (
  id uuid,
  display_name text,
  bio text,
  city text,
  gender text,
  height_cm smallint,
  age integer,
  is_verified boolean,
  created_at timestamptz,
  out_tonight_until timestamptz
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then
    raise exception 'Authentication required';
  end if;
  if not exists (
    select 1
    from public.profiles
    where profiles.id = v_user
      and account_status = 'ACTIVE'
  ) then
    raise exception 'Account unavailable';
  end if;

  return query
  select
    profile.id,
    profile.display_name,
    profile.bio,
    profile.city,
    profile.gender,
    profile.height_cm,
    date_part('year', age(current_date, private.date_of_birth))::integer,
    profile.is_verified,
    profile.created_at,
    profile.out_tonight_until
  from public.profiles as profile
  left join public.user_private as private on private.user_id = profile.id
  where profile.id <> v_user
    and not exists (
      select 1
      from public.mates as mate
      where mate.status = 'ACTIVE'
        and (
          (mate.user_one_id = v_user and mate.user_two_id = profile.id)
          or (mate.user_one_id = profile.id and mate.user_two_id = v_user)
        )
    )
  order by profile.created_at desc
  limit greatest(1, least(coalesce(p_limit, 500), 500));
end;
$$;

revoke all on function public.get_discovery_candidates(integer) from public, anon;
grant execute on function public.get_discovery_candidates(integer) to authenticated;

drop function if exists public.public_profile_cards(uuid[]);
create function public.public_profile_cards(p_ids uuid[])
returns table (
  id uuid,
  display_name text,
  bio text,
  city text,
  age integer,
  is_verified boolean,
  out_tonight_until timestamptz
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then
    raise exception 'Authentication required';
  end if;

  return query
  select
    profile.id,
    profile.display_name,
    profile.bio,
    profile.city,
    date_part('year', age(current_date, private.date_of_birth))::integer,
    profile.is_verified,
    profile.out_tonight_until
  from public.profiles as profile
  join public.user_private as private on private.user_id = profile.id
  where profile.id = any (coalesce(p_ids, array[]::uuid[]))
    and profile.id <> v_user
    and profile.account_status = 'ACTIVE'
    and not exists (
      select 1
      from public.user_blocks as block
      where (
        block.blocker_id = v_user
        and block.blocked_id = profile.id
      )
      or (
        block.blocker_id = profile.id
        and block.blocked_id = v_user
      )
    );
end;
$$;

revoke all on function public.public_profile_cards(uuid[]) from public, anon;
grant execute on function public.public_profile_cards(uuid[]) to authenticated;

notify pgrst, 'reload schema';

commit;
