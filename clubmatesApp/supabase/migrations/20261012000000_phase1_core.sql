-- Clubmates Phase 1 schema.
-- Seven tables only: profiles, user_private, profile_photos, passes,
-- invites, mates, user_blocks. Interests, nightlife, verification, chat,
-- notifications, and payments stay out of this migration.
--
-- Apply this to a development Supabase project, not the project that
-- serves clubmates.in.
--   cd clubmatesApp
--   supabase link --project-ref <dev-project-ref>
--   supabase db push
-- The SQL editor in that dev project also works.
--
-- After signup the app inserts profiles and user_private.
-- Photos land in the private profile-photos bucket at <auth.uid()>/<file>.
-- New photos stay PENDING. Discovery only returns APPROVED photos.
-- Approve test photos from the SQL editor as the project owner:
--   update public.profile_photos
--   set moderation_status = 'APPROVED'
--   where user_id = '<test-user-uuid>';
-- Deleting an auth user removes database rows. It does not delete Storage
-- objects. Do not describe account deletion as complete.

begin;

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null check (char_length(trim(display_name)) between 1 and 60),
  bio text check (bio is null or char_length(bio) <= 500),
  city text check (city is null or char_length(city) <= 100),
  gender text check (
    gender is null
    or gender in ('WOMAN', 'MAN', 'NON_BINARY', 'SELF_DESCRIBE', 'PREFER_NOT_TO_SAY')
  ),
  height_cm smallint check (height_cm is null or height_cm between 100 and 250),
  account_status text not null default 'ACTIVE' check (
    account_status in ('ACTIVE', 'PAUSED', 'SUSPENDED', 'DELETED')
  ),
  is_verified boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.user_private (
  user_id uuid primary key references auth.users (id) on delete cascade,
  date_of_birth date not null check (
    date_of_birth >= date '1900-01-01'
    and date_of_birth <= (current_date - interval '18 years')::date
  ),
  onboarding_completed boolean not null default false,
  discoverable boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.profile_photos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  storage_path text not null unique,
  display_order smallint not null check (display_order between 1 and 6),
  is_primary boolean not null default false,
  moderation_status text not null default 'PENDING' check (
    moderation_status in ('PENDING', 'APPROVED', 'REJECTED')
  ),
  created_at timestamptz not null default now(),
  unique (user_id, display_order)
);

create unique index profile_photos_one_primary_idx
  on public.profile_photos (user_id)
  where is_primary;

create index profile_photos_user_order_idx
  on public.profile_photos (user_id, display_order);

create table public.passes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  target_user_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  check (user_id <> target_user_id),
  unique (user_id, target_user_id)
);

create index passes_user_created_idx
  on public.passes (user_id, created_at desc);

create table public.invites (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles (id) on delete cascade,
  receiver_id uuid not null references public.profiles (id) on delete cascade,
  status text not null default 'PENDING' check (
    status in ('PENDING', 'ACCEPTED', 'DECLINED', 'CANCELLED', 'EXPIRED')
  ),
  message text check (message is null or char_length(message) <= 300),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  check (sender_id <> receiver_id)
);

create unique index invites_one_pending_idx
  on public.invites (sender_id, receiver_id)
  where status = 'PENDING';

create index invites_receiver_status_idx
  on public.invites (receiver_id, status, created_at desc);

create index invites_sender_idx
  on public.invites (sender_id, created_at desc);

create table public.mates (
  id uuid primary key default gen_random_uuid(),
  user_one_id uuid not null references public.profiles (id) on delete cascade,
  user_two_id uuid not null references public.profiles (id) on delete cascade,
  status text not null default 'ACTIVE' check (status in ('ACTIVE', 'ENDED')),
  created_at timestamptz not null default now(),
  check (user_one_id < user_two_id),
  unique (user_one_id, user_two_id)
);

create index mates_user_one_idx on public.mates (user_one_id, created_at desc);
create index mates_user_two_idx on public.mates (user_two_id, created_at desc);

create table public.user_blocks (
  blocker_id uuid not null references public.profiles (id) on delete cascade,
  blocked_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);

create index user_blocks_blocked_idx on public.user_blocks (blocked_id);

-- ---------------------------------------------------------------------------
-- Server-managed fields
-- ---------------------------------------------------------------------------

create function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create function public.protect_profile_fields()
returns trigger
language plpgsql
set search_path = ''
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

create function public.protect_photo_moderation()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if auth.uid() is not null
    and auth.uid() = old.user_id
    and new.moderation_status is distinct from old.moderation_status
  then
    raise exception 'Photo moderation status is managed by Clubmates';
  end if;
  return new;
end;
$$;

create trigger profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

create trigger user_private_updated_at
  before update on public.user_private
  for each row execute function public.set_updated_at();

create trigger profiles_protect_fields
  before update on public.profiles
  for each row execute function public.protect_profile_fields();

create trigger photos_protect_moderation
  before update on public.profile_photos
  for each row execute function public.protect_photo_moderation();

revoke all on function public.set_updated_at() from public, anon, authenticated;
revoke all on function public.protect_profile_fields() from public, anon, authenticated;
revoke all on function public.protect_photo_moderation() from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.user_private enable row level security;
alter table public.profile_photos enable row level security;
alter table public.passes enable row level security;
alter table public.invites enable row level security;
alter table public.mates enable row level security;
alter table public.user_blocks enable row level security;

create policy "Read visible profiles"
  on public.profiles
  for select
  to authenticated
  using (
    id = (select auth.uid())
    or (
      account_status = 'ACTIVE'
      and not exists (
        select 1
        from public.user_blocks as block
        where (
          block.blocker_id = (select auth.uid())
          and block.blocked_id = profiles.id
        )
        or (
          block.blocker_id = profiles.id
          and block.blocked_id = (select auth.uid())
        )
      )
    )
  );

create policy "Create own profile"
  on public.profiles
  for insert
  to authenticated
  with check (
    id = (select auth.uid())
    and is_verified = false
    and account_status = 'ACTIVE'
  );

create policy "Update own profile"
  on public.profiles
  for update
  to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

create policy "Read own private data"
  on public.user_private
  for select
  to authenticated
  using (user_id = (select auth.uid()));

create policy "Create own private data"
  on public.user_private
  for insert
  to authenticated
  with check (user_id = (select auth.uid()));

create policy "Update own private data"
  on public.user_private
  for update
  to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy "Read approved unblocked photos"
  on public.profile_photos
  for select
  to authenticated
  using (
    user_id = (select auth.uid())
    or (
      moderation_status = 'APPROVED'
      and exists (
        select 1
        from public.profiles as profile
        where profile.id = profile_photos.user_id
          and profile.account_status = 'ACTIVE'
      )
      and not exists (
        select 1
        from public.user_blocks as block
        where (
          block.blocker_id = (select auth.uid())
          and block.blocked_id = profile_photos.user_id
        )
        or (
          block.blocker_id = profile_photos.user_id
          and block.blocked_id = (select auth.uid())
        )
      )
    )
  );

create policy "Insert own pending photos"
  on public.profile_photos
  for insert
  to authenticated
  with check (
    user_id = (select auth.uid())
    and moderation_status = 'PENDING'
    and split_part(storage_path, '/', 1) = (select auth.uid())::text
  );

create policy "Update own photo metadata"
  on public.profile_photos
  for update
  to authenticated
  using (user_id = (select auth.uid()))
  with check (
    user_id = (select auth.uid())
    and split_part(storage_path, '/', 1) = (select auth.uid())::text
  );

create policy "Delete own photos"
  on public.profile_photos
  for delete
  to authenticated
  using (user_id = (select auth.uid()));

create policy "Read own passes"
  on public.passes
  for select
  to authenticated
  using (user_id = (select auth.uid()));

create policy "Create own passes"
  on public.passes
  for insert
  to authenticated
  with check (
    user_id = (select auth.uid())
    and exists (
      select 1
      from public.profiles as profile
      where profile.id = target_user_id
        and profile.account_status = 'ACTIVE'
    )
    and not exists (
      select 1
      from public.user_blocks as block
      where (
        block.blocker_id = (select auth.uid())
        and block.blocked_id = target_user_id
      )
      or (
        block.blocker_id = target_user_id
        and block.blocked_id = (select auth.uid())
      )
    )
  );

create policy "Invite participants read invites"
  on public.invites
  for select
  to authenticated
  using (
    sender_id = (select auth.uid())
    or receiver_id = (select auth.uid())
  );

create policy "Mate participants read mates"
  on public.mates
  for select
  to authenticated
  using (
    user_one_id = (select auth.uid())
    or user_two_id = (select auth.uid())
  );

create policy "Manage blocks I created"
  on public.user_blocks
  for all
  to authenticated
  using (blocker_id = (select auth.uid()))
  with check (blocker_id = (select auth.uid()));

-- ---------------------------------------------------------------------------
-- Privileges. Clients cannot insert invites or mates directly.
-- ---------------------------------------------------------------------------

revoke all on table
  public.profiles,
  public.user_private,
  public.profile_photos,
  public.passes,
  public.invites,
  public.mates,
  public.user_blocks
from public, anon;

grant select, insert, update on public.profiles to authenticated;
grant select, insert, update on public.user_private to authenticated;
grant select, insert, update, delete on public.profile_photos to authenticated;
grant select, insert on public.passes to authenticated;
grant select on public.invites to authenticated;
grant select on public.mates to authenticated;
grant select, insert, delete on public.user_blocks to authenticated;

-- ---------------------------------------------------------------------------
-- Invite and discovery functions
-- ---------------------------------------------------------------------------

create function public.create_invite(
  p_receiver_id uuid,
  p_message text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_sender uuid := auth.uid();
  v_id uuid;
begin
  if v_sender is null then
    raise exception 'Authentication required';
  end if;
  if p_receiver_id is null or p_receiver_id = v_sender then
    raise exception 'Invalid recipient';
  end if;
  if p_message is not null and char_length(p_message) > 300 then
    raise exception 'Message too long';
  end if;

  if not exists (
    select 1
    from public.profiles as profile
    join public.user_private as private on private.user_id = profile.id
    where profile.id = v_sender
      and profile.account_status = 'ACTIVE'
      and private.discoverable
      and private.date_of_birth <= (current_date - interval '18 years')::date
  ) then
    raise exception 'Sender is not eligible';
  end if;

  if not exists (
    select 1
    from public.profiles as profile
    join public.user_private as private on private.user_id = profile.id
    where profile.id = p_receiver_id
      and profile.account_status = 'ACTIVE'
      and private.discoverable
      and private.date_of_birth <= (current_date - interval '18 years')::date
  ) then
    raise exception 'Recipient unavailable';
  end if;

  if exists (
    select 1
    from public.user_blocks as block
    where (
      block.blocker_id = v_sender
      and block.blocked_id = p_receiver_id
    )
    or (
      block.blocker_id = p_receiver_id
      and block.blocked_id = v_sender
    )
  ) then
    raise exception 'Invite unavailable';
  end if;

  if exists (
    select 1
    from public.mates as mate
    where mate.status = 'ACTIVE'
      and (
        (mate.user_one_id = v_sender and mate.user_two_id = p_receiver_id)
        or (mate.user_one_id = p_receiver_id and mate.user_two_id = v_sender)
      )
  ) then
    raise exception 'Already mates';
  end if;

  insert into public.invites (sender_id, receiver_id, message)
  values (v_sender, p_receiver_id, p_message)
  returning id into v_id;

  return v_id;
exception
  when unique_violation then
    raise exception 'A pending invite already exists';
end;
$$;

create function public.respond_to_invite(
  p_invite_id uuid,
  p_accept boolean
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_inv public.invites%rowtype;
  v_one uuid;
  v_two uuid;
  v_mate uuid;
begin
  if v_user is null then
    raise exception 'Authentication required';
  end if;

  select *
  into v_inv
  from public.invites
  where id = p_invite_id
  for update;

  if not found then
    raise exception 'Invite not found';
  end if;
  if v_inv.receiver_id <> v_user then
    raise exception 'Only receiver can respond';
  end if;
  if v_inv.status <> 'PENDING' then
    raise exception 'Invite is no longer pending';
  end if;

  if exists (
    select 1
    from public.user_blocks as block
    where (
      block.blocker_id = v_inv.sender_id
      and block.blocked_id = v_inv.receiver_id
    )
    or (
      block.blocker_id = v_inv.receiver_id
      and block.blocked_id = v_inv.sender_id
    )
  ) then
    update public.invites
    set status = 'CANCELLED', responded_at = now()
    where id = p_invite_id;
    return null;
  end if;

  if p_accept then
    update public.invites
    set status = 'ACCEPTED', responded_at = now()
    where id = p_invite_id;

    v_one := least(v_inv.sender_id, v_inv.receiver_id);
    v_two := greatest(v_inv.sender_id, v_inv.receiver_id);

    insert into public.mates (user_one_id, user_two_id)
    values (v_one, v_two)
    on conflict (user_one_id, user_two_id)
    do update set status = 'ACTIVE'
    returning id into v_mate;

    return v_mate;
  end if;

  update public.invites
  set status = 'DECLINED', responded_at = now()
  where id = p_invite_id;
  return null;
end;
$$;

create function public.get_discovery_candidates(p_limit integer default 10)
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
  join public.user_private as private on private.user_id = profile.id
  where profile.id <> v_user
    and profile.account_status = 'ACTIVE'
    and private.discoverable
    and private.date_of_birth <= (current_date - interval '18 years')::date
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

revoke all on function public.create_invite(uuid, text) from public, anon;
grant execute on function public.create_invite(uuid, text) to authenticated;

revoke all on function public.respond_to_invite(uuid, boolean) from public, anon;
grant execute on function public.respond_to_invite(uuid, boolean) to authenticated;

revoke all on function public.get_discovery_candidates(integer) from public, anon;
grant execute on function public.get_discovery_candidates(integer) to authenticated;

-- ---------------------------------------------------------------------------
-- Private photo bucket. Owners can read their own files while pending.
-- Other users can read a file only after that photo is approved.
-- ---------------------------------------------------------------------------

insert into storage.buckets (id, name, "public", file_size_limit, allowed_mime_types)
values (
  'profile-photos',
  'profile-photos',
  false,
  8388608,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set
  "public" = excluded."public",
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Owners upload profile photos" on storage.objects;
drop policy if exists "Owners update profile photos" on storage.objects;
drop policy if exists "Owners delete profile photos" on storage.objects;
drop policy if exists "Owners read own profile photos" on storage.objects;
drop policy if exists "Read approved unblocked profile photos" on storage.objects;

create policy "Owners upload profile photos"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'profile-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Owners update profile photos"
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'profile-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'profile-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Owners delete profile photos"
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'profile-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Owners read own profile photos"
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'profile-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Read approved unblocked profile photos"
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'profile-photos'
    and exists (
      select 1
      from public.profile_photos as photo
      join public.profiles as profile on profile.id = photo.user_id
      where photo.storage_path = name
        and photo.moderation_status = 'APPROVED'
        and profile.account_status = 'ACTIVE'
        and not exists (
          select 1
          from public.user_blocks as block
          where (
            block.blocker_id = (select auth.uid())
            and block.blocked_id = photo.user_id
          )
          or (
            block.blocker_id = photo.user_id
            and block.blocked_id = (select auth.uid())
          )
        )
    )
  );

commit;
