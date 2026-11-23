-- CyberTrack 12 workspace sync.
-- Each account owns one JSON workspace. The RPC serializes merges under a row lock.
-- Items are merged by stable id; latest updatedAt wins. Keep deleted items as tombstones.

create table if not exists public.workspaces (
  user_id uuid primary key references auth.users(id) on delete cascade,
  items jsonb not null default '[]'::jsonb
    check (jsonb_typeof(items) = 'array'),
  updated_at timestamptz not null default now()
);

alter table public.workspaces enable row level security;

revoke all on table public.workspaces from anon;
grant select, insert, update on table public.workspaces to authenticated;

drop policy if exists "Users can read their own workspace" on public.workspaces;
create policy "Users can read their own workspace"
  on public.workspaces for select to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Users can create their own workspace" on public.workspaces;
create policy "Users can create their own workspace"
  on public.workspaces for insert to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can update their own workspace" on public.workspaces;
create policy "Users can update their own workspace"
  on public.workspaces for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create or replace function public.sync_workspace(p_items jsonb)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $function$
declare
  v_user_id uuid := auth.uid();
  v_server_items jsonb;
  v_merged_map jsonb := '{}'::jsonb;
  v_item jsonb;
  v_item_id text;
  v_existing jsonb;
  v_result jsonb;
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  if p_items is null or jsonb_typeof(p_items) <> 'array' then
    raise exception 'p_items must be a JSON array';
  end if;

  insert into public.workspaces (user_id, items)
  values (v_user_id, '[]'::jsonb)
  on conflict (user_id) do nothing;

  select items
    into v_server_items
    from public.workspaces
   where user_id = v_user_id
   for update;

  for v_item in
    select value
      from jsonb_array_elements(v_server_items || p_items) as entries(value)
  loop
    v_item_id := v_item ->> 'id';
    if v_item_id is null or length(v_item_id) = 0 then
      raise exception 'Every workspace item must contain a non-empty id';
    end if;

    v_existing := v_merged_map -> v_item_id;

    if v_existing is null
       or coalesce(nullif(v_item ->> 'updatedAt', '')::timestamptz, 'epoch'::timestamptz)
          >= coalesce(nullif(v_existing ->> 'updatedAt', '')::timestamptz, 'epoch'::timestamptz)
    then
      v_merged_map := v_merged_map || jsonb_build_object(v_item_id, v_item);
    end if;
  end loop;

  select coalesce(jsonb_agg(value), '[]'::jsonb)
    into v_result
    from jsonb_each(v_merged_map);

  update public.workspaces
     set items = v_result,
         updated_at = now()
   where user_id = v_user_id;

  return v_result;
end;
$function$;

revoke all on function public.sync_workspace(jsonb) from public, anon;
grant execute on function public.sync_workspace(jsonb) to authenticated;

-- Enable Realtime for the workspace table if it is not already published.
do $publication$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
     and not exists (
       select 1
         from pg_publication_tables
        where pubname = 'supabase_realtime'
          and schemaname = 'public'
          and tablename = 'workspaces'
     )
  then
    execute 'alter publication supabase_realtime add table public.workspaces';
  end if;
end;
$publication$;
