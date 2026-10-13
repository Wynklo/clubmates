-- Store the signed-in person's coordinates on their profile.
-- Other people cannot read these columns. Discovery can use them later
-- inside a security-definer function without returning the raw point.

begin;

alter table public.profiles
  add column if not exists latitude double precision,
  add column if not exists longitude double precision,
  add column if not exists location_updated_at timestamptz;

alter table public.profiles
  drop constraint if exists profiles_latitude_range;
alter table public.profiles
  add constraint profiles_latitude_range
  check (latitude is null or (latitude >= -90 and latitude <= 90));

alter table public.profiles
  drop constraint if exists profiles_longitude_range;
alter table public.profiles
  add constraint profiles_longitude_range
  check (longitude is null or (longitude >= -180 and longitude <= 180));

-- A table-level SELECT includes every column. Replace it so the client
-- can still read the public profile fields and cannot read coordinates.
revoke select on table public.profiles from authenticated;
grant select (
  id,
  display_name,
  bio,
  city,
  gender,
  height_cm,
  account_status,
  is_verified,
  created_at,
  updated_at
) on table public.profiles to authenticated;

notify pgrst, 'reload schema';

commit;
