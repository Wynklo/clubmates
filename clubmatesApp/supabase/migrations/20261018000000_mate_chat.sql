-- Mate chat (issue #4).
--
-- One thread per mates row. Only the two people in an ACTIVE mate
-- connection, with no block either way and both accounts ACTIVE, can read
-- or write it. Clients never insert or update messages directly; every
-- write goes through a security definer function that checks access,
-- length, links, duplicates, and rate limits.
--
-- The v1 schema left an unused public.messages table (with conversations);
-- chat uses public.mate_messages instead.
--
-- Typing indicators use private Realtime broadcast channels named
-- chat:<mate id>, guarded by policies on realtime.messages.
-- Photos live in the private chat-images bucket at
-- <sender id>/<mate id>/<file>.
--
-- Deletion policy:
--   * A sender can unsend a message at any time. Text is cleared and the
--     photo is queued for removal.
--   * Blocking someone ends the mate connection, which closes the thread.
--   * Messages in a closed thread are deleted 30 days after it closed.
--   * Deleting an account deletes every thread that account was part of.
-- Photo files are removed through the Storage API by the chat-cleanup
-- Edge Function, because SQL cannot remove the stored file itself.

begin;

-- ---------------------------------------------------------------------------
-- When a mate connection closed
-- ---------------------------------------------------------------------------

alter table public.mates
  add column if not exists ended_at timestamptz;

update public.mates
set ended_at = now()
where status = 'ENDED'
  and ended_at is null;

create or replace function public.stamp_mate_ended()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.status = 'ENDED' and old.status is distinct from 'ENDED' then
    new.ended_at := now();
  elsif new.status = 'ACTIVE' then
    new.ended_at := null;
  end if;
  return new;
end;
$$;

revoke all on function public.stamp_mate_ended() from public, anon, authenticated;

drop trigger if exists mates_stamp_ended on public.mates;
create trigger mates_stamp_ended
  before update of status on public.mates
  for each row execute function public.stamp_mate_ended();

-- Blocking someone ends the mate connection with them.
create or replace function public.end_mate_on_block()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.mates
  set status = 'ENDED'
  where status = 'ACTIVE'
    and user_one_id = least(new.blocker_id, new.blocked_id)
    and user_two_id = greatest(new.blocker_id, new.blocked_id);
  return null;
end;
$$;

revoke all on function public.end_mate_on_block() from public, anon, authenticated;

drop trigger if exists user_blocks_end_mate on public.user_blocks;
create trigger user_blocks_end_mate
  after insert on public.user_blocks
  for each row execute function public.end_mate_on_block();

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table if not exists public.mate_messages (
  id uuid primary key default gen_random_uuid(),
  mate_id uuid not null references public.mates (id) on delete cascade,
  sender_id uuid not null references public.profiles (id) on delete cascade,
  client_id uuid,
  body text check (body is null or char_length(body) between 1 and 1000),
  image_path text check (image_path is null or char_length(image_path) <= 300),
  created_at timestamptz not null default now(),
  read_at timestamptz,
  deleted_at timestamptz,
  check (deleted_at is not null or body is not null or image_path is not null)
);

create index if not exists mate_messages_thread_idx
  on public.mate_messages (mate_id, created_at desc, id desc);

create index if not exists mate_messages_sender_idx
  on public.mate_messages (sender_id, created_at desc);

create unique index if not exists mate_messages_client_idx
  on public.mate_messages (sender_id, client_id)
  where client_id is not null;

alter table public.mate_messages replica identity full;

create table if not exists public.chat_image_trash (
  path text primary key,
  queued_at timestamptz not null default now()
);

-- user_reports came from the v1 schema. Reports must outlive either
-- account, so the people links become ON DELETE SET NULL, and the message
-- text is copied in at report time. Reports are filed only through
-- report_user, which rate-limits them.
alter table public.user_reports
  add column if not exists message_id uuid,
  add column if not exists message_body text;

alter table public.user_reports
  alter column reporter_id drop not null,
  alter column reported_user_id drop not null;

alter table public.user_reports
  drop constraint if exists user_reports_reporter_id_fkey,
  drop constraint if exists user_reports_reported_user_id_fkey;

alter table public.user_reports
  add constraint user_reports_reporter_id_fkey
    foreign key (reporter_id) references public.profiles (id) on delete set null,
  add constraint user_reports_reported_user_id_fkey
    foreign key (reported_user_id) references public.profiles (id) on delete set null;

create index if not exists user_reports_reporter_idx
  on public.user_reports (reporter_id, created_at desc);

drop policy if exists "Submit report" on public.user_reports;

alter table public.mate_messages enable row level security;
alter table public.chat_image_trash enable row level security;
alter table public.user_reports enable row level security;

revoke all on public.mate_messages from public, anon, authenticated;
revoke all on public.chat_image_trash from public, anon, authenticated;
revoke insert, update, delete on public.user_reports from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Access helpers
-- ---------------------------------------------------------------------------

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

create or replace function public.chat_topic_mate(p_topic text)
returns uuid
language sql
immutable
set search_path = ''
as $$
  select case
    when p_topic ~ '^chat:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    then substr(p_topic, 6)::uuid
  end;
$$;

create or replace function public.chat_path_mate(p_name text)
returns uuid
language sql
immutable
set search_path = ''
as $$
  select case
    when split_part(p_name, '/', 2) ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    then split_part(p_name, '/', 2)::uuid
  end;
$$;

revoke all on function public.can_access_mate(uuid) from public, anon;
revoke all on function public.chat_topic_mate(text) from public, anon;
revoke all on function public.chat_path_mate(text) from public, anon;
grant execute on function public.can_access_mate(uuid) to authenticated;
grant execute on function public.chat_topic_mate(text) to authenticated;
grant execute on function public.chat_path_mate(text) to authenticated;

drop policy if exists "Mates read their thread" on public.mate_messages;
create policy "Mates read their thread"
  on public.mate_messages
  for select
  to authenticated
  using (public.can_access_mate(mate_id));

grant select on public.mate_messages to authenticated;

-- ---------------------------------------------------------------------------
-- Sending, reading, unsending
-- ---------------------------------------------------------------------------

create or replace function public.send_message(
  p_mate_id uuid,
  p_body text default null,
  p_image_path text default null,
  p_client_id uuid default null
)
returns public.mate_messages
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_body text := nullif(btrim(coalesce(p_body, '')), '');
  v_row public.mate_messages;
  v_count integer;
begin
  if v_user is null then
    raise exception 'Authentication required';
  end if;

  if p_client_id is not null then
    select * into v_row
    from public.mate_messages
    where sender_id = v_user and client_id = p_client_id;
    if found then
      return v_row;
    end if;
  end if;

  if not public.can_access_mate(p_mate_id) then
    raise exception 'This chat is closed.';
  end if;
  if v_body is null and p_image_path is null then
    raise exception 'Write a message first.';
  end if;
  if char_length(v_body) > 1000 then
    raise exception 'Messages can be up to 1000 characters.';
  end if;
  if v_body is not null
    and (select count(*) from regexp_matches(v_body, '(https?://|www\.)', 'gi')) > 2
  then
    raise exception 'Too many links in one message.';
  end if;

  if p_image_path is not null then
    if p_image_path !~ ('^' || v_user::text || '/' || p_mate_id::text || '/[A-Za-z0-9_-]{8,64}\.(jpg|png|webp)$') then
      raise exception 'That photo could not be sent.';
    end if;
    if not exists (
      select 1 from storage.objects
      where bucket_id = 'chat-images'
        and name = p_image_path
        and owner_id = v_user::text
    ) then
      raise exception 'That photo could not be sent.';
    end if;
    select count(*) into v_count
    from public.mate_messages
    where sender_id = v_user
      and image_path is not null
      and created_at > now() - interval '1 day';
    if v_count >= 30 then
      raise exception 'You can send up to 30 photos a day.';
    end if;
  end if;

  select count(*) into v_count
  from public.mate_messages
  where sender_id = v_user
    and created_at > now() - interval '1 minute';
  if v_count >= 20 then
    raise exception 'Slow down a little. Try again in a minute.';
  end if;

  select count(*) into v_count
  from public.mate_messages
  where sender_id = v_user
    and created_at > now() - interval '1 day';
  if v_count >= 1000 then
    raise exception 'You have reached today''s message limit.';
  end if;

  if v_body is not null then
    select count(*) into v_count
    from public.mate_messages
    where sender_id = v_user
      and mate_id = p_mate_id
      and body = v_body
      and created_at > now() - interval '10 minutes';
    if v_count >= 3 then
      raise exception 'You already sent that.';
    end if;
  end if;

  insert into public.mate_messages (mate_id, sender_id, client_id, body, image_path)
  values (p_mate_id, v_user, p_client_id, v_body, p_image_path)
  returning * into v_row;
  return v_row;
end;
$$;

create or replace function public.mark_thread_read(p_mate_id uuid)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_count integer;
begin
  if v_user is null then
    raise exception 'Authentication required';
  end if;
  if not public.can_access_mate(p_mate_id) then
    return 0;
  end if;
  update public.mate_messages
  set read_at = now()
  where mate_id = p_mate_id
    and sender_id <> v_user
    and read_at is null;
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

create or replace function public.queue_chat_cleanup()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_url text;
  v_secret text;
begin
  if not exists (select 1 from public.chat_image_trash) then
    return;
  end if;
  select regexp_replace(decrypted_secret, '/notify$', '/chat-cleanup') into v_url
  from vault.decrypted_secrets
  where name = 'notify_url';
  select decrypted_secret into v_secret
  from vault.decrypted_secrets
  where name = 'notify_secret';
  if v_url is null or v_secret is null then
    return;
  end if;
  perform net.http_post(
    url := v_url,
    body := '{}'::jsonb,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-notify-secret', v_secret
    ),
    timeout_milliseconds := 10000
  );
end;
$$;

create or replace function public.delete_message(p_message_id uuid)
returns public.mate_messages
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_row public.mate_messages;
begin
  if v_user is null then
    raise exception 'Authentication required';
  end if;

  select * into v_row
  from public.mate_messages
  where id = p_message_id
    and sender_id = v_user
  for update;
  if not found then
    raise exception 'Message unavailable';
  end if;
  if v_row.deleted_at is not null then
    return v_row;
  end if;

  if v_row.image_path is not null then
    insert into public.chat_image_trash (path)
    values (v_row.image_path)
    on conflict do nothing;
  end if;

  update public.mate_messages
  set body = null,
      image_path = null,
      deleted_at = now()
  where id = p_message_id
  returning * into v_row;

  perform public.queue_chat_cleanup();
  return v_row;
end;
$$;

-- One row per open thread for the Mates list: last message and unread count.
create or replace function public.mate_threads()
returns table (
  mate_id uuid,
  last_body text,
  last_kind text,
  last_at timestamptz,
  last_mine boolean,
  unread integer
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    mate.id,
    last.body,
    case
      when last.id is null then null
      when last.deleted_at is not null then 'removed'
      when last.image_path is not null then 'photo'
      else 'text'
    end,
    last.created_at,
    last.sender_id = (select auth.uid()),
    (
      select count(*)::integer
      from public.mate_messages as unread
      where unread.mate_id = mate.id
        and unread.sender_id <> (select auth.uid())
        and unread.read_at is null
        and unread.deleted_at is null
    )
  from public.mates as mate
  left join lateral (
    select message.*
    from public.mate_messages as message
    where message.mate_id = mate.id
    order by message.created_at desc, message.id desc
    limit 1
  ) as last on true
  where (select auth.uid()) in (mate.user_one_id, mate.user_two_id)
    and public.can_access_mate(mate.id);
$$;

revoke all on function public.send_message(uuid, text, text, uuid) from public, anon;
revoke all on function public.mark_thread_read(uuid) from public, anon;
revoke all on function public.delete_message(uuid) from public, anon;
revoke all on function public.mate_threads() from public, anon;
revoke all on function public.queue_chat_cleanup() from public, anon, authenticated;
grant execute on function public.send_message(uuid, text, text, uuid) to authenticated;
grant execute on function public.mark_thread_read(uuid) to authenticated;
grant execute on function public.delete_message(uuid) to authenticated;
grant execute on function public.mate_threads() to authenticated;

-- ---------------------------------------------------------------------------
-- Reports
-- ---------------------------------------------------------------------------

create or replace function public.report_user(
  p_user_id uuid,
  p_reason text,
  p_details text default null,
  p_message_id uuid default null,
  p_block boolean default false
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_body text;
  v_count integer;
begin
  if v_user is null then
    raise exception 'Authentication required';
  end if;
  if p_user_id is null or p_user_id = v_user then
    raise exception 'Report unavailable';
  end if;
  if not exists (select 1 from public.profiles where id = p_user_id) then
    raise exception 'Report unavailable';
  end if;
  if p_reason is null or p_reason not in (
    'HARASSMENT', 'FAKE_PROFILE', 'INAPPROPRIATE_CONTENT', 'SCAM', 'SPAM', 'UNDERAGE', 'OTHER'
  ) then
    raise exception 'Choose a reason.';
  end if;
  if p_details is not null and char_length(p_details) > 500 then
    raise exception 'Keep the details under 500 characters.';
  end if;

  select count(*) into v_count
  from public.user_reports
  where reporter_id = v_user
    and created_at > now() - interval '1 day';
  if v_count >= 10 then
    raise exception 'You have sent a lot of reports today. Try again tomorrow.';
  end if;

  if p_message_id is not null then
    select message.body into v_body
    from public.mate_messages as message
    join public.mates as mate on mate.id = message.mate_id
    where message.id = p_message_id
      and message.sender_id = p_user_id
      and v_user in (mate.user_one_id, mate.user_two_id);
    if not found then
      raise exception 'Report unavailable';
    end if;
  end if;

  insert into public.user_reports (
    reporter_id, reported_user_id, message_id, message_body, reason, description
  )
  values (
    v_user, p_user_id, p_message_id, v_body, p_reason, nullif(btrim(p_details), '')
  );

  if p_block then
    insert into public.user_blocks (blocker_id, blocked_id)
    values (v_user, p_user_id)
    on conflict do nothing;
  end if;
end;
$$;

revoke all on function public.report_user(uuid, text, text, uuid, boolean) from public, anon;
grant execute on function public.report_user(uuid, text, text, uuid, boolean) to authenticated;

-- ---------------------------------------------------------------------------
-- Realtime: message changes and private typing channels
-- ---------------------------------------------------------------------------

do $$
begin
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    create publication supabase_realtime;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'mate_messages'
  ) then
    alter publication supabase_realtime add table public.mate_messages;
  end if;
end;
$$;

drop policy if exists "Mates join their chat channel" on realtime.messages;
create policy "Mates join their chat channel"
  on realtime.messages
  for select
  to authenticated
  using (
    realtime.messages.extension in ('broadcast', 'presence')
    and public.can_access_mate(public.chat_topic_mate((select realtime.topic())))
  );

drop policy if exists "Mates send on their chat channel" on realtime.messages;
create policy "Mates send on their chat channel"
  on realtime.messages
  for insert
  to authenticated
  with check (
    realtime.messages.extension in ('broadcast', 'presence')
    and public.can_access_mate(public.chat_topic_mate((select realtime.topic())))
  );

-- ---------------------------------------------------------------------------
-- Photo storage
-- ---------------------------------------------------------------------------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'chat-images',
  'chat-images',
  false,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = false,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Mates upload chat images" on storage.objects;
create policy "Mates upload chat images"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'chat-images'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and public.can_access_mate(public.chat_path_mate(name))
  );

drop policy if exists "Mates read chat images" on storage.objects;
create policy "Mates read chat images"
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'chat-images'
    and public.can_access_mate(public.chat_path_mate(name))
    and exists (
      select 1 from public.mate_messages as message
      where message.image_path = storage.objects.name
        and message.deleted_at is null
    )
  );

-- The uploader can still read a file that has no message yet, so a failed
-- send can be retried.
drop policy if exists "Senders read own pending chat images" on storage.objects;
create policy "Senders read own pending chat images"
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'chat-images'
    and owner_id = (select auth.uid())::text
    and public.can_access_mate(public.chat_path_mate(name))
  );

-- ---------------------------------------------------------------------------
-- Push for new messages
-- ---------------------------------------------------------------------------

create or replace function public.queue_message_push()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_url text;
  v_secret text;
begin
  select decrypted_secret into v_url
  from vault.decrypted_secrets
  where name = 'notify_url';
  select decrypted_secret into v_secret
  from vault.decrypted_secrets
  where name = 'notify_secret';
  if v_url is null or v_secret is null then
    return null;
  end if;
  perform net.http_post(
    url := v_url,
    body := jsonb_build_object('kind', 'message', 'message_id', new.id),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-notify-secret', v_secret
    ),
    timeout_milliseconds := 5000
  );
  return null;
end;
$$;

revoke all on function public.queue_message_push() from public, anon, authenticated;

drop trigger if exists mate_messages_queue_push on public.mate_messages;
create trigger mate_messages_queue_push
  after insert on public.mate_messages
  for each row execute function public.queue_message_push();

-- ---------------------------------------------------------------------------
-- Retention and account deletion
-- ---------------------------------------------------------------------------

create or replace function public.purge_closed_threads()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_count integer;
begin
  insert into public.chat_image_trash (path)
  select message.image_path
  from public.mate_messages as message
  join public.mates as mate on mate.id = message.mate_id
  where mate.status = 'ENDED'
    and mate.ended_at < now() - interval '30 days'
    and message.image_path is not null
  on conflict do nothing;

  delete from public.mate_messages as message
  using public.mates as mate
  where mate.id = message.mate_id
    and mate.status = 'ENDED'
    and mate.ended_at < now() - interval '30 days';
  get diagnostics v_count = row_count;

  perform public.queue_chat_cleanup();
  return v_count;
end;
$$;

revoke all on function public.purge_closed_threads() from public, anon, authenticated;

create or replace function public.delete_own_account()
returns void
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

  insert into public.chat_image_trash (path)
  select message.image_path
  from public.mate_messages as message
  join public.mates as mate on mate.id = message.mate_id
  where v_user in (mate.user_one_id, mate.user_two_id)
    and message.image_path is not null
  on conflict do nothing;

  delete from auth.users
  where id = v_user;

  perform public.queue_chat_cleanup();
end;
$$;

revoke all on function public.delete_own_account() from public, anon;
grant execute on function public.delete_own_account() to authenticated;

notify pgrst, 'reload schema';

commit;

-- Daily cleanup. pg_cron lives outside the transaction above.
create extension if not exists pg_cron;

select cron.unschedule(jobid)
from cron.job
where jobname = 'clubmates-chat-cleanup';

select cron.schedule(
  'clubmates-chat-cleanup',
  '30 21 * * *',
  'select public.purge_closed_threads(); select public.queue_chat_cleanup();'
);
