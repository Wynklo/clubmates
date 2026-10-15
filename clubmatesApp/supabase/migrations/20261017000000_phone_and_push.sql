-- Real phone sign-in and push notifications.
--
-- The firebase-session Edge Function sets auth.users.phone after Firebase
-- verifies the number. user_private.phone_e164 is always copied from there,
-- so members cannot write their own phone.
--
-- Pushes are sent by the notify Edge Function. The invites trigger calls it
-- through pg_net with a shared secret kept in Vault (notify_url and
-- notify_secret), never in this file.

begin;

create extension if not exists pg_net;

-- ---------------------------------------------------------------------------
-- Verified phone and notification switches
-- ---------------------------------------------------------------------------

alter table public.user_private
  add column if not exists phone_e164 text unique,
  add column if not exists notify_invites boolean not null default true,
  add column if not exists notify_mates boolean not null default true,
  add column if not exists notify_nearby boolean not null default false;

create or replace function public.sync_private_phone()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_phone text;
begin
  select nullif(phone, '')
  into v_phone
  from auth.users
  where id = new.user_id;

  new.phone_e164 := case
    when v_phone is null then null
    when v_phone like '+%' then v_phone
    else '+' || v_phone
  end;
  return new;
end;
$$;

revoke all on function public.sync_private_phone() from public, anon, authenticated;

drop trigger if exists user_private_sync_phone on public.user_private;
create trigger user_private_sync_phone
  before insert or update on public.user_private
  for each row execute function public.sync_private_phone();

create or replace function public.push_auth_phone()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.user_private
  set updated_at = now()
  where user_id = new.id;
  return null;
end;
$$;

revoke all on function public.push_auth_phone() from public, anon, authenticated;

drop trigger if exists auth_users_phone_to_private on auth.users;
create trigger auth_users_phone_to_private
  after update of phone on auth.users
  for each row
  when (old.phone is distinct from new.phone)
  execute function public.push_auth_phone();

-- ---------------------------------------------------------------------------
-- Device tokens
-- ---------------------------------------------------------------------------

create table if not exists public.device_tokens (
  token text primary key check (char_length(token) between 20 and 4096),
  user_id uuid not null references auth.users (id) on delete cascade,
  platform text not null check (platform in ('android', 'ios')),
  updated_at timestamptz not null default now()
);

create index if not exists device_tokens_user_idx
  on public.device_tokens (user_id);

alter table public.device_tokens enable row level security;
revoke all on public.device_tokens from public, anon, authenticated;

drop policy if exists "Read own device tokens" on public.device_tokens;
create policy "Read own device tokens"
  on public.device_tokens
  for select
  to authenticated
  using (user_id = (select auth.uid()));

grant select on public.device_tokens to authenticated;

-- A phone can move between accounts after logout or reinstall, so the
-- token is reassigned to whoever is signed in now.
create or replace function public.register_device_token(
  p_token text,
  p_platform text
)
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

  insert into public.device_tokens (token, user_id, platform, updated_at)
  values (p_token, v_user, p_platform, now())
  on conflict (token) do update
  set user_id = excluded.user_id,
      platform = excluded.platform,
      updated_at = now();
end;
$$;

create or replace function public.remove_device_token(p_token text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  delete from public.device_tokens
  where token = p_token
    and user_id = auth.uid();
end;
$$;

revoke all on function public.register_device_token(text, text) from public, anon;
revoke all on function public.remove_device_token(text) from public, anon;
grant execute on function public.register_device_token(text, text) to authenticated;
grant execute on function public.remove_device_token(text) to authenticated;

-- ---------------------------------------------------------------------------
-- Sign-in rate limit, used only by firebase-session with the service role
-- ---------------------------------------------------------------------------

create table if not exists public.auth_exchange_attempts (
  id bigint generated always as identity primary key,
  bucket text not null,
  created_at timestamptz not null default now()
);

create index if not exists auth_exchange_attempts_bucket_idx
  on public.auth_exchange_attempts (bucket, created_at desc);

alter table public.auth_exchange_attempts enable row level security;
revoke all on public.auth_exchange_attempts from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Invite pushes
-- ---------------------------------------------------------------------------

create or replace function public.queue_invite_push()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_kind text;
  v_url text;
  v_secret text;
begin
  if tg_op = 'INSERT' and new.status = 'PENDING' then
    v_kind := 'invite';
  elsif tg_op = 'UPDATE'
    and new.status = 'ACCEPTED'
    and old.status is distinct from 'ACCEPTED'
  then
    v_kind := 'accepted';
  else
    return null;
  end if;

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
    body := jsonb_build_object('kind', v_kind, 'invite_id', new.id),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-notify-secret', v_secret
    ),
    timeout_milliseconds := 5000
  );
  return null;
end;
$$;

revoke all on function public.queue_invite_push() from public, anon, authenticated;

drop trigger if exists invites_queue_push on public.invites;
create trigger invites_queue_push
  after insert or update of status on public.invites
  for each row execute function public.queue_invite_push();

notify pgrst, 'reload schema';

commit;
