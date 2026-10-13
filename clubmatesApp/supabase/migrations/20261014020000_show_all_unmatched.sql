-- Temporary Club list: every profile except the viewer and current matches.

begin;

create or replace function public.get_discovery_candidates(p_limit integer default 500)
returns table (
  id uuid,
  display_name text,
  bio text,
  city text,
  gender text,
  height_cm smallint,
  age integer,
  is_verified boolean,
  created_at timestamptz
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
    profile.created_at
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

notify pgrst, 'reload schema';

commit;
