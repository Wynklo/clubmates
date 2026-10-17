-- Chat hardening: strip the default Supabase table grants down to what the
-- app actually uses, and keep anonymous (guest) sessions out of every chat
-- surface. Row level security still applies on top of these grants.

-- Chat tables: no access at all for signed-out callers.
revoke all on table public.mate_messages from anon, public;
revoke all on table public.mates from anon, public;
revoke all on table public.user_reports from anon, public;
revoke all on table public.chat_image_trash from anon, authenticated, public;
revoke all on table public.notifications from anon, public;

-- Members only ever read these; every write goes through a checked RPC.
revoke insert, update, delete, truncate, references, trigger
  on table public.mate_messages from authenticated;
revoke insert, update, delete, truncate, references, trigger
  on table public.mates from authenticated;
revoke insert, update, delete, truncate, references, trigger
  on table public.user_reports from authenticated;
grant select on table public.mate_messages to authenticated;
grant select on table public.mates to authenticated;
grant select on table public.user_reports to authenticated;

-- Notifications: members read and mark their own as read.
revoke insert, delete, truncate, references, trigger
  on table public.notifications from authenticated;
grant select, update on table public.notifications to authenticated;

-- Profiles: keep the existing column-level read grants untouched; only drop
-- the table-wide powers row level security can't police.
revoke all on table public.profiles from anon, public;
revoke truncate, references, trigger on table public.profiles from authenticated;

-- A thread is only visible to its two mates, both active, unblocked, and
-- signed in with a real (non-anonymous) account.
create or replace function public.can_access_mate(p_mate_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.mates as mate
    join public.profiles as one on one.id = mate.user_one_id
    join public.profiles as two on two.id = mate.user_two_id
    where mate.id = p_mate_id
      and mate.status = 'ACTIVE'
      and (select auth.uid()) in (mate.user_one_id, mate.user_two_id)
      and coalesce(((select auth.jwt()) ->> 'is_anonymous')::boolean, false) = false
      and one.account_status = 'ACTIVE'
      and two.account_status = 'ACTIVE'
      and not exists (
        select 1
        from public.user_blocks as block
        where (block.blocker_id = mate.user_one_id and block.blocked_id = mate.user_two_id)
           or (block.blocker_id = mate.user_two_id and block.blocked_id = mate.user_one_id)
      )
  );
$$;

revoke all on function public.can_access_mate(uuid) from public, anon;
grant execute on function public.can_access_mate(uuid) to authenticated;

-- Chat RPCs: signed-in members only.
do $$
declare
  fn regprocedure;
begin
  for fn in
    select p.oid::regprocedure
    from pg_proc as p
    join pg_namespace as n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname in (
        'send_message', 'mark_thread_read', 'delete_message',
        'mate_threads', 'report_user'
      )
  loop
    execute format('revoke all on function %s from public, anon', fn);
    execute format('grant execute on function %s to authenticated', fn);
  end loop;
end
$$;

-- Internal helpers are never callable from the API.
do $$
declare
  fn regprocedure;
begin
  for fn in
    select p.oid::regprocedure
    from pg_proc as p
    join pg_namespace as n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname in ('queue_chat_cleanup', 'purge_closed_threads', 'queue_message_push')
  loop
    execute format('revoke all on function %s from public, anon, authenticated', fn);
  end loop;
end
$$;

-- The Club deck never shows someone you blocked or who blocked you, and only
-- shows active accounts.
create or replace function public.get_discovery_candidates(p_limit integer default 500)
returns table(
  id uuid,
  display_name text,
  bio text,
  city text,
  gender text,
  height_cm smallint,
  age integer,
  is_verified boolean,
  created_at timestamp with time zone,
  out_tonight_until timestamp with time zone
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
    and profile.account_status = 'ACTIVE'
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
      where (block.blocker_id = v_user and block.blocked_id = profile.id)
         or (block.blocker_id = profile.id and block.blocked_id = v_user)
    )
  order by profile.created_at desc
  limit greatest(1, least(coalesce(p_limit, 500), 500));
end;
$$;

revoke all on function public.get_discovery_candidates(integer) from public, anon;
grant execute on function public.get_discovery_candidates(integer) to authenticated;
