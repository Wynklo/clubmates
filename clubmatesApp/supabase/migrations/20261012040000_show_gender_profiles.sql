-- Test Club should show every profile of the gender someone asked to meet.
-- New photos are marked approved so a person appears as soon as they finish signup.

begin;

create or replace function public.protect_photo_moderation()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if auth.uid() is not null
    and auth.uid() = old.user_id
    and new.moderation_status is distinct from old.moderation_status
    and not (old.moderation_status = 'PENDING' and new.moderation_status = 'APPROVED')
  then
    raise exception 'Photo moderation status is managed by Clubmates';
  end if;
  return new;
end;
$$;

create or replace function public.approve_new_profile_photo()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.moderation_status = 'PENDING' then
    update public.profile_photos
    set moderation_status = 'APPROVED'
    where id = new.id;
  end if;
  return new;
end;
$$;

drop trigger if exists approve_new_profile_photo on public.profile_photos;

create trigger approve_new_profile_photo
  after insert on public.profile_photos
  for each row
  execute function public.approve_new_profile_photo();

revoke all on function public.approve_new_profile_photo() from public, anon, authenticated;

update public.profile_photos
set moderation_status = 'APPROVED'
where moderation_status = 'PENDING';

commit;
