-- What a member is up for tonight, and the nightlife they are into.
-- Both are shown on profiles like the bio, so they share its visibility.

begin;

alter table public.profiles
  add column if not exists plan_tonight text,
  add column if not exists interests text[] not null default '{}';

alter table public.profiles
  drop constraint if exists profiles_plan_tonight_length;
alter table public.profiles
  add constraint profiles_plan_tonight_length
  check (plan_tonight is null or char_length(plan_tonight) between 1 and 120);

alter table public.profiles
  drop constraint if exists profiles_interests_size;
alter table public.profiles
  add constraint profiles_interests_size
  check (
    cardinality(interests) <= 6
    and char_length(array_to_string(interests, '')) <= 180
    and array_position(interests, null) is null
  );

grant select (plan_tonight, interests) on table public.profiles to authenticated;

notify pgrst, 'reload schema';

commit;
