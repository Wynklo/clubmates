-- Who the member wants to meet. Club uses this to filter discovery.

begin;

alter table public.user_private
  add column interested_in text check (
    interested_in is null
    or interested_in in ('WOMAN', 'MAN', 'NON_BINARY', 'EVERYONE')
  );

create or replace function public.get_discovery_candidates(p_limit integer default 10)
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
  v_interest text;
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

  select private.interested_in
  into v_interest
  from public.user_private as private
  where private.user_id = v_user;

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
  join public.user_private as private on private.user_id = profile.id
  where profile.id <> v_user
    and profile.account_status = 'ACTIVE'
    and private.discoverable
    and private.date_of_birth <= (current_date - interval '18 years')::date
    and (
      v_interest is null
      or v_interest = 'EVERYONE'
      or profile.gender = v_interest
    )
    and not exists (
      select 1
      from public.passes as pass
      where pass.user_id = v_user
        and pass.target_user_id = profile.id
    )
    and not exists (
      select 1
      from public.invites as invite
      where (
        invite.sender_id = v_user
        and invite.receiver_id = profile.id
        and invite.status in ('PENDING', 'ACCEPTED')
      )
      or (
        invite.sender_id = profile.id
        and invite.receiver_id = v_user
        and invite.status = 'PENDING'
      )
    )
    and not exists (
      select 1
      from public.mates as mate
      where mate.status = 'ACTIVE'
        and (
          (mate.user_one_id = v_user and mate.user_two_id = profile.id)
          or (mate.user_one_id = profile.id and mate.user_two_id = v_user)
        )
    )
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
    )
    and exists (
      select 1
      from public.profile_photos as photo
      where photo.user_id = profile.id
        and photo.moderation_status = 'APPROVED'
    )
  order by profile.created_at desc
  limit greatest(1, least(coalesce(p_limit, 10), 30));
end;
$$;

revoke all on function public.get_discovery_candidates(integer) from public, anon;
grant execute on function public.get_discovery_candidates(integer) to authenticated;

commit;
