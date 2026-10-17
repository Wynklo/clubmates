-- Profile prompts: up to three short question-and-answer cards per member,
-- shown between photos on a profile. Visible to other members only while the
-- owner is active and neither side has blocked the other, like photos.

create table if not exists public.profile_prompts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  position smallint not null check (position between 1 and 3),
  prompt text not null check (char_length(btrim(prompt)) between 3 and 80),
  answer text not null check (char_length(btrim(answer)) between 1 and 200),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, position)
);

create index if not exists profile_prompts_user_idx
  on public.profile_prompts (user_id, position);

alter table public.profile_prompts enable row level security;

revoke all on table public.profile_prompts from anon, public;
revoke all on table public.profile_prompts from authenticated;
grant select, insert, update, delete on table public.profile_prompts to authenticated;

drop policy if exists "Read own or visible prompts" on public.profile_prompts;
create policy "Read own or visible prompts"
on public.profile_prompts
for select
to authenticated
using (
  user_id = (select auth.uid())
  or (
    exists (
      select 1
      from public.profiles as profile
      where profile.id = profile_prompts.user_id
        and profile.account_status = 'ACTIVE'
    )
    and not exists (
      select 1
      from public.user_blocks as block
      where (block.blocker_id = (select auth.uid()) and block.blocked_id = profile_prompts.user_id)
         or (block.blocker_id = profile_prompts.user_id and block.blocked_id = (select auth.uid()))
    )
  )
);

drop policy if exists "Write own prompts" on public.profile_prompts;
create policy "Write own prompts"
on public.profile_prompts
for insert
to authenticated
with check (user_id = (select auth.uid()));

drop policy if exists "Update own prompts" on public.profile_prompts;
create policy "Update own prompts"
on public.profile_prompts
for update
to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

drop policy if exists "Delete own prompts" on public.profile_prompts;
create policy "Delete own prompts"
on public.profile_prompts
for delete
to authenticated
using (user_id = (select auth.uid()));

drop trigger if exists profile_prompts_updated_at on public.profile_prompts;
create trigger profile_prompts_updated_at
before update on public.profile_prompts
for each row execute function public.set_updated_at();
