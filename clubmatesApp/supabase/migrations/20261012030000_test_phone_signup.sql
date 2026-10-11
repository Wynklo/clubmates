-- Temporary test sign-up. Any Indian mobile can register with the app
-- until SMS is enabled, and only five new numbers are allowed.
-- Seeded profiles and the original test number are not part of that five.

begin;

create or replace function public.limit_test_phone_signups()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  existing integer;
begin
  if new.email is null
    or new.email !~ '^[6-9][0-9]{9}@clubmates\.dev$'
  then
    return new;
  end if;

  if new.email_confirmed_at is null then
    new.email_confirmed_at := now();
  end if;

  if new.email = '9999999999@clubmates.dev' then
    return new;
  end if;

  select count(*)
  into existing
  from auth.users
  where email ~ '^[6-9][0-9]{9}@clubmates\.dev$'
    and email <> '9999999999@clubmates.dev';

  if existing >= 5 then
    raise exception 'Only 5 test numbers can register';
  end if;

  return new;
end;
$$;

drop trigger if exists limit_test_phone_signups on auth.users;

create trigger limit_test_phone_signups
  before insert on auth.users
  for each row
  execute function public.limit_test_phone_signups();

create or replace function public.test_phone_slots()
returns integer
language sql
stable
security definer
set search_path = ''
as $$
  select greatest(
    0,
    5 - count(*)::integer
  )
  from auth.users
  where email ~ '^[6-9][0-9]{9}@clubmates\.dev$'
    and email <> '9999999999@clubmates.dev';
$$;

revoke all on function public.limit_test_phone_signups() from public, anon, authenticated;
revoke all on function public.test_phone_slots() from public, anon;
grant execute on function public.test_phone_slots() to anon, authenticated;

commit;
