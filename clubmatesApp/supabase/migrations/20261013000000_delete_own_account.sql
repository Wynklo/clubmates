-- A signed-in person can delete their own account.
-- profiles and user_private reference auth.users with ON DELETE CASCADE.
-- Photos, passes, invites, mates, and blocks reference profiles the same way,
-- so removing the auth user removes those rows.
-- Storage files are removed by the app through the Storage API before this
-- function runs. Supabase rejects DELETE against storage.objects.

begin;

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

  delete from auth.users
  where id = v_user;
end;
$$;

revoke all on function public.delete_own_account() from public, anon;
grant execute on function public.delete_own_account() to authenticated;

commit;
