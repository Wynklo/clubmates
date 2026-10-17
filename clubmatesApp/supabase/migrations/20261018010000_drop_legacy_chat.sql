-- Drops the v1 chat tables. Mate chat lives in public.mate_messages.
-- respond_to_invite still wrote a conversations row on accept, so it is
-- recreated without that line first. Everything else in it is unchanged.

begin;

create or replace function public.respond_to_invite(p_invite_id uuid, p_accept boolean)
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
  if v_user is null then raise exception 'Authentication required'; end if;
  select * into v_inv from public.invites where id = p_invite_id for update;
  if not found then raise exception 'Invite not found'; end if;
  if v_inv.receiver_id <> v_user then raise exception 'Only receiver can respond'; end if;
  if v_inv.status <> 'PENDING' then raise exception 'Invite is no longer pending'; end if;
  if exists (
    select 1 from public.user_blocks b
    where (b.blocker_id = v_inv.sender_id and b.blocked_id = v_inv.receiver_id)
       or (b.blocker_id = v_inv.receiver_id and b.blocked_id = v_inv.sender_id)
  ) then
    update public.invites set status = 'CANCELLED', responded_at = now() where id = p_invite_id;
    return null;
  end if;
  if p_accept then
    update public.invites set status = 'ACCEPTED', responded_at = now() where id = p_invite_id;
    v_one := least(v_inv.sender_id, v_inv.receiver_id);
    v_two := greatest(v_inv.sender_id, v_inv.receiver_id);
    insert into public.mates (user_one_id, user_two_id) values (v_one, v_two)
      on conflict (user_one_id, user_two_id) do update set status = 'ACTIVE'
      returning id into v_mate;
    insert into public.notifications (user_id, notification_type, title, body, reference_id) values
      (v_inv.sender_id, 'INVITE_ACCEPTED', 'Invite accepted', 'Your invite was accepted.', v_mate),
      (v_inv.receiver_id, 'NEW_MATE', 'You are mates', 'You can now make plans together.', v_mate);
    return v_mate;
  else
    update public.invites set status = 'DECLINED', responded_at = now() where id = p_invite_id;
    insert into public.notifications (user_id, notification_type, title, body, reference_id)
      values (v_inv.sender_id, 'INVITE_DECLINED', 'Invite declined', 'Your invite was declined.', p_invite_id);
    return null;
  end if;
end;
$$;

revoke all on function public.respond_to_invite(uuid, boolean) from public, anon;
grant execute on function public.respond_to_invite(uuid, boolean) to authenticated;

drop table if exists public.messages;
drop table if exists public.conversations;

notify pgrst, 'reload schema';

commit;
