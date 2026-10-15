-- Used only by the firebase-session Edge Function with the service role.
-- Accounts made by the old test sign-in have no phone yet, only the email
-- <10 digits>@clubmates.dev, so both are checked.

begin;

create or replace function public.auth_user_for_phone(
  p_phone text,
  p_legacy_email text
)
returns table (id uuid, email text, has_phone boolean)
language sql
stable
security definer
set search_path = ''
as $$
  select
    account.id,
    account.email::text,
    coalesce(account.phone, '') <> ''
  from auth.users as account
  where account.phone = p_phone
    or lower(account.email) = lower(p_legacy_email)
  order by (account.phone = p_phone) desc nulls last
  limit 1;
$$;

revoke all on function public.auth_user_for_phone(text, text) from public, anon, authenticated;
grant execute on function public.auth_user_for_phone(text, text) to service_role;

commit;
