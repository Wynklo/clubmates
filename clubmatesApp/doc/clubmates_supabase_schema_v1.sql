-- Clubmates Supabase schema V1
-- Run in Supabase SQL Editor as project owner. Review/test before production.
-- Normal app operations use Supabase client + RLS; payment/KYC/provider webhooks use Edge Functions.
-- Never put the service_role key in the mobile/web client.

begin;
create extension if not exists pgcrypto with schema extensions;

-- CORE DATA: public profile fields are separated from DOB/private account data.
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(trim(display_name)) between 1 and 60),
  bio text check (bio is null or char_length(bio) <= 500),
  city text check (city is null or char_length(city) <= 100),
  gender text check (gender is null or gender in ('WOMAN','MAN','NON_BINARY','SELF_DESCRIBE','PREFER_NOT_TO_SAY')),
  height_cm smallint check (height_cm is null or height_cm between 100 and 250),
  account_status text not null default 'ACTIVE' check (account_status in ('ACTIVE','PAUSED','SUSPENDED','DELETED')),
  is_verified boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.user_private (
  user_id uuid primary key references auth.users(id) on delete cascade,
  date_of_birth date not null check (
    date_of_birth >= date '1900-01-01'
    and date_of_birth <= (current_date - interval '18 years')::date
  ),
  onboarding_completed boolean not null default false,
  discoverable boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.profile_photos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  storage_path text not null unique,
  display_order smallint not null check (display_order between 1 and 6),
  is_primary boolean not null default false,
  moderation_status text not null default 'PENDING' check (moderation_status in ('PENDING','APPROVED','REJECTED')),
  created_at timestamptz not null default now(),
  unique (user_id, display_order)
);
create unique index if not exists profile_photos_one_primary_idx on public.profile_photos(user_id) where is_primary;
create index if not exists profile_photos_user_order_idx on public.profile_photos(user_id, display_order);

create table if not exists public.interests (
  id bigint generated always as identity primary key,
  name text not null unique check (char_length(trim(name)) between 1 and 60),
  category text,
  is_active boolean not null default true
);
create table if not exists public.user_interests (
  user_id uuid not null references public.profiles(id) on delete cascade,
  interest_id bigint not null references public.interests(id) on delete restrict,
  created_at timestamptz not null default now(),
  primary key (user_id, interest_id)
);
create index if not exists user_interests_interest_idx on public.user_interests(interest_id);

create table if not exists public.user_preferences (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  min_age smallint not null default 18 check (min_age between 18 and 100),
  max_age smallint not null default 40 check (max_age between 18 and 100),
  max_distance_km smallint not null default 25 check (max_distance_km between 1 and 500),
  preferred_genders text[] not null default '{}',
  updated_at timestamptz not null default now(),
  check (min_age <= max_age)
);
create table if not exists public.nightlife_preferences (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  preferred_vibes text[] not null default '{}',
  preferred_group_size smallint check (preferred_group_size is null or preferred_group_size between 1 and 20),
  preferred_days text[] not null default '{}',
  spontaneous_plans boolean not null default true,
  updated_at timestamptz not null default now()
);

-- DISCOVERY / CONNECTIONS
create table if not exists public.passes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  target_user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  check (user_id <> target_user_id),
  unique (user_id, target_user_id)
);
create index if not exists passes_user_created_idx on public.passes(user_id, created_at desc);

create table if not exists public.invites (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles(id) on delete cascade,
  receiver_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'PENDING' check (status in ('PENDING','ACCEPTED','DECLINED','CANCELLED','EXPIRED')),
  message text check (message is null or char_length(message) <= 300),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  check (sender_id <> receiver_id)
);
create unique index if not exists invites_one_pending_idx on public.invites(sender_id, receiver_id) where status = 'PENDING';
create index if not exists invites_receiver_status_idx on public.invites(receiver_id, status, created_at desc);
create index if not exists invites_sender_idx on public.invites(sender_id, created_at desc);

create table if not exists public.mates (
  id uuid primary key default gen_random_uuid(),
  user_one_id uuid not null references public.profiles(id) on delete cascade,
  user_two_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'ACTIVE' check (status in ('ACTIVE','ENDED')),
  created_at timestamptz not null default now(),
  check (user_one_id < user_two_id),
  unique (user_one_id, user_two_id)
);
create index if not exists mates_user_one_idx on public.mates(user_one_id, created_at desc);
create index if not exists mates_user_two_idx on public.mates(user_two_id, created_at desc);

-- SAFETY / VERIFICATION / NOTIFICATIONS / CONSENT
create table if not exists public.user_blocks (
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);
create index if not exists user_blocks_blocked_idx on public.user_blocks(blocked_id);

create table if not exists public.user_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  reported_user_id uuid not null references public.profiles(id) on delete cascade,
  reason text not null check (reason in ('HARASSMENT','FAKE_PROFILE','INAPPROPRIATE_CONTENT','SCAM','SPAM','UNDERAGE','OTHER')),
  description text check (description is null or char_length(description) <= 2000),
  status text not null default 'OPEN' check (status in ('OPEN','IN_REVIEW','RESOLVED','DISMISSED')),
  created_at timestamptz not null default now(),
  resolved_at timestamptz,
  check (reporter_id <> reported_user_id)
);
create index if not exists reports_status_created_idx on public.user_reports(status, created_at);

create table if not exists public.identity_verifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  provider text,
  provider_reference_id text,
  verification_type text not null check (verification_type in ('IDENTITY','PAN','AADHAAR','KYC')),
  status text not null default 'PENDING' check (status in ('PENDING','VERIFIED','FAILED','EXPIRED','CANCELLED')),
  verified_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists identity_verifications_user_idx on public.identity_verifications(user_id, created_at desc);

create table if not exists public.face_verifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  provider text,
  provider_reference_id text,
  status text not null default 'PENDING' check (status in ('PENDING','VERIFIED','FAILED','EXPIRED','CANCELLED')),
  verified_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists face_verifications_user_idx on public.face_verifications(user_id, created_at desc);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  notification_type text not null check (notification_type in ('NEW_INVITE','INVITE_ACCEPTED','INVITE_DECLINED','NEW_MATE','NEW_MESSAGE','VERIFICATION_COMPLETE','SYSTEM')),
  title text not null check (char_length(title) <= 120),
  body text not null check (char_length(body) <= 500),
  reference_id uuid,
  read_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists notifications_unread_idx on public.notifications(user_id, created_at desc) where read_at is null;

create table if not exists public.user_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  device_token text not null,
  platform text not null check (platform in ('IOS','ANDROID','WEB')),
  app_version text,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (user_id, device_token)
);

create table if not exists public.user_consents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  consent_type text not null check (consent_type in ('TERMS','PRIVACY','LOCATION','MARKETING','AGE_ELIGIBILITY')),
  version text not null,
  granted boolean not null,
  recorded_at timestamptz not null default now()
);
create index if not exists user_consents_user_time_idx on public.user_consents(user_id, recorded_at desc);

create table if not exists public.audit_logs (
  id bigint generated always as identity primary key,
  actor_user_id uuid,
  event_type text not null,
  target_type text,
  target_id text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists audit_logs_created_idx on public.audit_logs(created_at desc);

-- Optional messaging tables
create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  mate_id uuid not null unique references public.mates(id) on delete cascade,
  created_at timestamptz not null default now(),
  last_message_at timestamptz
);
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  message_type text not null default 'TEXT' check (message_type in ('TEXT','IMAGE')),
  content text not null check (char_length(content) between 1 and 4000),
  created_at timestamptz not null default now(),
  read_at timestamptz
);
create index if not exists messages_conversation_created_idx on public.messages(conversation_id, created_at desc);

-- UPDATED_AT + server-managed fields
create or replace function public.set_updated_at()
returns trigger language plpgsql set search_path = ''
as $$ begin new.updated_at := now(); return new; end; $$;

create or replace function public.protect_profile_fields()
returns trigger language plpgsql set search_path = ''
as $$
begin
  if auth.uid() is not null and auth.uid() = old.id then
    if new.is_verified is distinct from old.is_verified then
      raise exception 'Verification status is managed by Clubmates';
    end if;
    if new.account_status is distinct from old.account_status then
      raise exception 'Account status is managed by Clubmates';
    end if;
  end if;
  return new;
end;
$$;

create or replace function public.protect_photo_moderation()
returns trigger language plpgsql set search_path = ''
as $$
begin
  if auth.uid() is not null and auth.uid() = old.user_id
     and new.moderation_status is distinct from old.moderation_status then
    raise exception 'Photo moderation status is managed by Clubmates';
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_updated_at on public.profiles;
create trigger profiles_updated_at before update on public.profiles for each row execute function public.set_updated_at();
drop trigger if exists user_private_updated_at on public.user_private;
create trigger user_private_updated_at before update on public.user_private for each row execute function public.set_updated_at();
drop trigger if exists identity_updated_at on public.identity_verifications;
create trigger identity_updated_at before update on public.identity_verifications for each row execute function public.set_updated_at();
drop trigger if exists face_updated_at on public.face_verifications;
create trigger face_updated_at before update on public.face_verifications for each row execute function public.set_updated_at();
drop trigger if exists profiles_protect_fields on public.profiles;
create trigger profiles_protect_fields before update on public.profiles for each row execute function public.protect_profile_fields();
drop trigger if exists photos_protect_moderation on public.profile_photos;
create trigger photos_protect_moderation before update on public.profile_photos for each row execute function public.protect_photo_moderation();

-- RLS on EVERY table in public schema created above
do $$
declare t text;
begin
  foreach t in array array[
    'profiles','user_private','profile_photos','interests','user_interests','user_preferences',
    'nightlife_preferences','passes','invites','mates','user_blocks','user_reports',
    'identity_verifications','face_verifications','notifications','user_devices','user_consents',
    'audit_logs','conversations','messages'
  ] loop
    execute format('alter table public.%I enable row level security', t);
  end loop;
end $$;

-- RLS policies. Public profile table contains only display fields.
create policy "Read active profiles" on public.profiles for select to authenticated using (account_status = 'ACTIVE');
create policy "Create own profile" on public.profiles for insert to authenticated
with check (
  id = (select auth.uid())
  and is_verified = false
  and account_status = 'ACTIVE'
);
create policy "Update own profile" on public.profiles for update to authenticated using (id = (select auth.uid())) with check (id = (select auth.uid()));

create policy "Read own private data" on public.user_private for select to authenticated using (user_id = (select auth.uid()));
create policy "Create own private data" on public.user_private for insert to authenticated with check (user_id = (select auth.uid()));
create policy "Update own private data" on public.user_private for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

create policy "Read approved unblocked photos" on public.profile_photos for select to authenticated using (
  (user_id = (select auth.uid())) or (
    moderation_status = 'APPROVED'
    and exists (select 1 from public.profiles p where p.id = profile_photos.user_id and p.account_status = 'ACTIVE')
    and not exists (select 1 from public.user_blocks b where
      (b.blocker_id = (select auth.uid()) and b.blocked_id = profile_photos.user_id)
      or (b.blocker_id = profile_photos.user_id and b.blocked_id = (select auth.uid())))
  )
);
create policy "Insert own pending photos" on public.profile_photos for insert to authenticated
with check (
  user_id = (select auth.uid())
  and moderation_status = 'PENDING'
  and split_part(storage_path, '/', 1) = (select auth.uid())::text
);
create policy "Update own photo metadata" on public.profile_photos for update to authenticated
using (user_id = (select auth.uid()))
with check (
  user_id = (select auth.uid())
  and split_part(storage_path, '/', 1) = (select auth.uid())::text
);
create policy "Delete own photos" on public.profile_photos for delete to authenticated using (user_id = (select auth.uid()));

create policy "Read active interests" on public.interests for select to authenticated using (is_active);
create policy "Read own interests" on public.user_interests for select to authenticated using (user_id = (select auth.uid()));
create policy "Add own interests" on public.user_interests for insert to authenticated with check (user_id = (select auth.uid()));
create policy "Remove own interests" on public.user_interests for delete to authenticated using (user_id = (select auth.uid()));

create policy "Manage own preferences" on public.user_preferences for all to authenticated
using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "Manage own nightlife preferences" on public.nightlife_preferences for all to authenticated
using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

create policy "Read own passes" on public.passes for select to authenticated using (user_id = (select auth.uid()));
create policy "Create own passes" on public.passes for insert to authenticated with check (
  user_id = (select auth.uid())
  and exists (select 1 from public.profiles p where p.id = target_user_id and p.account_status = 'ACTIVE')
  and not exists (select 1 from public.user_blocks b where
    (b.blocker_id = (select auth.uid()) and b.blocked_id = target_user_id)
    or (b.blocker_id = target_user_id and b.blocked_id = (select auth.uid())))
);
create policy "Invite participants read invites" on public.invites for select to authenticated
using (sender_id = (select auth.uid()) or receiver_id = (select auth.uid()));
-- No direct invite writes: use RPC functions.
create policy "Mate participants read mates" on public.mates for select to authenticated
using (user_one_id = (select auth.uid()) or user_two_id = (select auth.uid()));
-- No direct mate writes: use RPC functions.

create policy "Manage blocks I created" on public.user_blocks for all to authenticated
using (blocker_id = (select auth.uid())) with check (blocker_id = (select auth.uid()));
create policy "Submit report" on public.user_reports for insert to authenticated
with check (reporter_id = (select auth.uid()));
create policy "Read reports I submitted" on public.user_reports for select to authenticated
using (reporter_id = (select auth.uid()));

create policy "Read own identity verification status" on public.identity_verifications for select to authenticated
using (user_id = (select auth.uid()));
create policy "Read own face verification status" on public.face_verifications for select to authenticated
using (user_id = (select auth.uid()));

create policy "Read own notifications" on public.notifications for select to authenticated
using (user_id = (select auth.uid()));
create policy "Update own notifications" on public.notifications for update to authenticated
using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

create policy "Manage own devices" on public.user_devices for all to authenticated
using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "Record own consent" on public.user_consents for insert to authenticated
with check (user_id = (select auth.uid()));
create policy "Read own consent" on public.user_consents for select to authenticated
using (user_id = (select auth.uid()));

create policy "Read conversations as mate" on public.conversations for select to authenticated using (
  exists (select 1 from public.mates m where m.id = conversations.mate_id and m.status = 'ACTIVE'
    and (m.user_one_id = (select auth.uid()) or m.user_two_id = (select auth.uid())))
);
create policy "Read messages as mate" on public.messages for select to authenticated using (
  exists (select 1 from public.conversations c join public.mates m on m.id = c.mate_id
    where c.id = messages.conversation_id and m.status = 'ACTIVE'
      and (m.user_one_id = (select auth.uid()) or m.user_two_id = (select auth.uid()))
      and not exists (select 1 from public.user_blocks b where
        (b.blocker_id = m.user_one_id and b.blocked_id = m.user_two_id)
        or (b.blocker_id = m.user_two_id and b.blocked_id = m.user_one_id)))
);
create policy "Send messages as self to mate" on public.messages for insert to authenticated with check (
  sender_id = (select auth.uid())
  and exists (select 1 from public.conversations c join public.mates m on m.id = c.mate_id
    where c.id = messages.conversation_id and m.status = 'ACTIVE'
      and (m.user_one_id = (select auth.uid()) or m.user_two_id = (select auth.uid()))
      and not exists (select 1 from public.user_blocks b where
        (b.blocker_id = m.user_one_id and b.blocked_id = m.user_two_id)
        or (b.blocker_id = m.user_two_id and b.blocked_id = m.user_one_id)))
);
-- audit_logs intentionally has no client policies.

-- TRANSACTIONAL RPC: create invite, prevent self/blocked/mates/ineligible users, notify recipient.
create or replace function public.create_invite(p_receiver_id uuid, p_message text default null)
returns uuid language plpgsql security definer set search_path = ''
as $$
declare v_sender uuid := auth.uid(); v_id uuid;
begin
  if v_sender is null then raise exception 'Authentication required'; end if;
  if p_receiver_id is null or p_receiver_id = v_sender then raise exception 'Invalid recipient'; end if;
  if p_message is not null and char_length(p_message) > 300 then raise exception 'Message too long'; end if;
  if not exists (select 1 from public.profiles p join public.user_private u on u.user_id=p.id
    where p.id=v_sender and p.account_status='ACTIVE' and u.discoverable
      and u.date_of_birth <= (current_date - interval '18 years')::date) then
    raise exception 'Sender is not eligible';
  end if;
  if not exists (select 1 from public.profiles p join public.user_private u on u.user_id=p.id
    where p.id=p_receiver_id and p.account_status='ACTIVE' and u.discoverable
      and u.date_of_birth <= (current_date - interval '18 years')::date) then
    raise exception 'Recipient unavailable';
  end if;
  if exists (select 1 from public.user_blocks b where
    (b.blocker_id=v_sender and b.blocked_id=p_receiver_id) or (b.blocker_id=p_receiver_id and b.blocked_id=v_sender))
  then raise exception 'Invite unavailable'; end if;
  if exists (select 1 from public.mates m where m.status='ACTIVE' and
    ((m.user_one_id=v_sender and m.user_two_id=p_receiver_id) or (m.user_one_id=p_receiver_id and m.user_two_id=v_sender)))
  then raise exception 'Already mates'; end if;
  insert into public.invites(sender_id, receiver_id, message) values (v_sender,p_receiver_id,p_message) returning id into v_id;
  insert into public.notifications(user_id,notification_type,title,body,reference_id)
    values (p_receiver_id,'NEW_INVITE','New invite','Someone wants to go out with you.',v_id);
  return v_id;
exception when unique_violation then raise exception 'A pending invite already exists';
end;
$$;

-- TRANSACTIONAL RPC: only invite receiver can accept/decline; accepting creates one mate + conversation.
create or replace function public.respond_to_invite(p_invite_id uuid, p_accept boolean)
returns uuid language plpgsql security definer set search_path = ''
as $$
declare v_user uuid := auth.uid(); v_inv public.invites%rowtype; v_one uuid; v_two uuid; v_mate uuid;
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  select * into v_inv from public.invites where id=p_invite_id for update;
  if not found then raise exception 'Invite not found'; end if;
  if v_inv.receiver_id <> v_user then raise exception 'Only receiver can respond'; end if;
  if v_inv.status <> 'PENDING' then raise exception 'Invite is no longer pending'; end if;
  if exists (select 1 from public.user_blocks b where
    (b.blocker_id=v_inv.sender_id and b.blocked_id=v_inv.receiver_id) or (b.blocker_id=v_inv.receiver_id and b.blocked_id=v_inv.sender_id))
  then update public.invites set status='CANCELLED', responded_at=now() where id=p_invite_id;
       return null;
  end if;
  if p_accept then
    update public.invites set status='ACCEPTED',responded_at=now() where id=p_invite_id;
    v_one := least(v_inv.sender_id,v_inv.receiver_id); v_two := greatest(v_inv.sender_id,v_inv.receiver_id);
    insert into public.mates(user_one_id,user_two_id) values (v_one,v_two)
      on conflict (user_one_id,user_two_id) do update set status='ACTIVE' returning id into v_mate;
    insert into public.conversations(mate_id) values (v_mate) on conflict (mate_id) do nothing;
    insert into public.notifications(user_id,notification_type,title,body,reference_id) values
      (v_inv.sender_id,'INVITE_ACCEPTED','Invite accepted','Your invite was accepted.',v_mate),
      (v_inv.receiver_id,'NEW_MATE','You are mates','You can now make plans together.',v_mate);
    return v_mate;
  else
    update public.invites set status='DECLINED',responded_at=now() where id=p_invite_id;
    insert into public.notifications(user_id,notification_type,title,body,reference_id)
      values (v_inv.sender_id,'INVITE_DECLINED','Invite declined','Your invite was declined.',p_invite_id);
    return null;
  end if;
end;
$$;

-- Discovery RPC returns only display-safe fields (age, not DOB); excludes passes, invites, mates and blocks.
create or replace function public.get_discovery_candidates(p_limit integer default 10)
returns table (id uuid, display_name text, bio text, city text, gender text, height_cm smallint, age integer, is_verified boolean, created_at timestamptz)
language plpgsql security definer set search_path = ''
as $$
declare v_user uuid := auth.uid(); v_min smallint; v_max smallint;
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  if not exists (select 1 from public.profiles where profiles.id=v_user and account_status='ACTIVE')
  then raise exception 'Account unavailable'; end if;
  select coalesce(pref.min_age,18),coalesce(pref.max_age,100) into v_min,v_max
    from (select 1) x left join public.user_preferences pref on pref.user_id=v_user;
  return query
  select p.id,p.display_name,p.bio,p.city,p.gender,p.height_cm,
    date_part('year',age(current_date,priv.date_of_birth))::integer,p.is_verified,p.created_at
  from public.profiles p join public.user_private priv on priv.user_id=p.id
  where p.id<>v_user and p.account_status='ACTIVE' and priv.discoverable
    and priv.date_of_birth <= (current_date - interval '18 years')::date
    and date_part('year',age(current_date,priv.date_of_birth)) between v_min and v_max
    and not exists (select 1 from public.passes pa where pa.user_id=v_user and pa.target_user_id=p.id)
    and not exists (select 1 from public.invites i where
      (i.sender_id=v_user and i.receiver_id=p.id and i.status in ('PENDING','ACCEPTED'))
      or (i.sender_id=p.id and i.receiver_id=v_user and i.status='PENDING'))
    and not exists (select 1 from public.mates m where m.status='ACTIVE' and
      ((m.user_one_id=v_user and m.user_two_id=p.id) or (m.user_one_id=p.id and m.user_two_id=v_user)))
    and not exists (select 1 from public.user_blocks b where
      (b.blocker_id=v_user and b.blocked_id=p.id) or (b.blocker_id=p.id and b.blocked_id=v_user))
    and exists (select 1 from public.profile_photos ph where ph.user_id=p.id and ph.moderation_status='APPROVED')
  order by p.created_at desc limit greatest(1,least(coalesce(p_limit,10),30));
end;
$$;

create or replace function public.mark_notification_read(p_notification_id uuid)
returns boolean language plpgsql security definer set search_path = ''
as $$
declare v_user uuid := auth.uid();
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  update public.notifications set read_at=coalesce(read_at,now())
    where id=p_notification_id and user_id=v_user;
  return found;
end;
$$;

revoke all on function public.create_invite(uuid,text) from public, anon;
grant execute on function public.create_invite(uuid,text) to authenticated;
revoke all on function public.respond_to_invite(uuid,boolean) from public, anon;
grant execute on function public.respond_to_invite(uuid,boolean) to authenticated;
revoke all on function public.get_discovery_candidates(integer) from public, anon;
grant execute on function public.get_discovery_candidates(integer) to authenticated;
revoke all on function public.mark_notification_read(uuid) from public, anon;
grant execute on function public.mark_notification_read(uuid) to authenticated;

-- SQL privileges + RLS. Keep audit log private; verification rows are service-written only.
grant usage on schema public to authenticated;
grant select,insert,update on public.profiles to authenticated;
grant select,insert,update on public.user_private to authenticated;
grant select,insert,update,delete on public.profile_photos to authenticated;
grant select on public.interests to authenticated;
grant select,insert,delete on public.user_interests to authenticated;
grant select,insert,update,delete on public.user_preferences, public.nightlife_preferences to authenticated;
grant select,insert on public.passes to authenticated;
grant select on public.invites,public.mates to authenticated;
grant select,insert,delete on public.user_blocks to authenticated;
grant select,insert on public.user_reports to authenticated;
grant select on public.identity_verifications,public.face_verifications to authenticated;
grant select,update on public.notifications to authenticated;
grant select,insert,update,delete on public.user_devices to authenticated;
grant select,insert on public.user_consents to authenticated;
grant select on public.conversations to authenticated;
grant select,insert on public.messages to authenticated;
revoke all on public.audit_logs from anon,authenticated;

commit;

-- STORAGE SETUP:
-- In Dashboard > Storage create a PRIVATE bucket named "profile-photos".
-- Suggested limit: 8 MB. Allowed MIME types: image/jpeg, image/png, image/webp.
-- Object path format: <auth.uid()>/<unique-filename>. Run these policies after bucket creation.

drop policy if exists "Owners upload profile photos" on storage.objects;
create policy "Owners upload profile photos" on storage.objects for insert to authenticated
with check (bucket_id='profile-photos' and (storage.foldername(name))[1]=(select auth.uid())::text);

drop policy if exists "Owners update profile photos" on storage.objects;
create policy "Owners update profile photos" on storage.objects for update to authenticated
using (bucket_id='profile-photos' and (storage.foldername(name))[1]=(select auth.uid())::text)
with check (bucket_id='profile-photos' and (storage.foldername(name))[1]=(select auth.uid())::text);

drop policy if exists "Owners delete profile photos" on storage.objects;
create policy "Owners delete profile photos" on storage.objects for delete to authenticated
using (bucket_id='profile-photos' and (storage.foldername(name))[1]=(select auth.uid())::text);

drop policy if exists "Read approved unblocked profile photos" on storage.objects;
create policy "Read approved unblocked profile photos" on storage.objects for select to authenticated
using (
  bucket_id='profile-photos'
  and exists (
    select 1 from public.profile_photos ph join public.profiles p on p.id=ph.user_id
    where ph.storage_path=name and ph.moderation_status='APPROVED' and p.account_status='ACTIVE'
      and not exists (select 1 from public.user_blocks b where
        (b.blocker_id=(select auth.uid()) and b.blocked_id=ph.user_id)
        or (b.blocker_id=ph.user_id and b.blocked_id=(select auth.uid())))
  )
);

-- UI RPC examples:
-- supabase.rpc('get_discovery_candidates', { p_limit: 10 })
-- supabase.rpc('create_invite', { p_receiver_id: userId, p_message: null })
-- supabase.rpc('respond_to_invite', { p_invite_id: inviteId, p_accept: true })
-- supabase.rpc('mark_notification_read', { p_notification_id: notificationId })
-- On signup create public.profiles + public.user_private from authenticated UI.
-- KYC/payment records must be written by trusted Edge Functions/webhooks, not client updates.
