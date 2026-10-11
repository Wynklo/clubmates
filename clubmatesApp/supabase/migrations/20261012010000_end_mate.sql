-- A participant can end a Mate connection. Clients still cannot update mates directly.

begin;

create function public.end_mate(p_mate_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_updated integer;
begin
  if v_user is null then
    raise exception 'Authentication required';
  end if;
  if p_mate_id is null then
    raise exception 'Invite unavailable';
  end if;

  update public.mates
  set status = 'ENDED'
  where id = p_mate_id
    and status = 'ACTIVE'
    and (user_one_id = v_user or user_two_id = v_user);

  get diagnostics v_updated = row_count;
  if v_updated = 0 then
    raise exception 'Invite unavailable';
  end if;
end;
$$;

revoke all on function public.end_mate(uuid) from public, anon;
grant execute on function public.end_mate(uuid) to authenticated;

-- Age for people the caller already has a reason to see. Never returns date of birth.
create function public.public_profile_cards(p_ids uuid[])
returns table (
  id uuid,
  display_name text,
  bio text,
  city text,
  age integer,
  is_verified boolean
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
    profile.is_verified
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

commit;
