-- Automatic order status flow:
-- Обработка -> Принят -> Готовится -> Готов -> Выдан.
-- Every non-terminal status lasts a random 1-7 seconds.

create extension if not exists pg_cron with schema pg_catalog;

create table if not exists public.order_statuses (
  id smallint primary key,
  code text not null unique,
  name text not null unique,
  position smallint not null unique,
  min_duration_seconds smallint not null default 1,
  max_duration_seconds smallint not null default 7,
  is_terminal boolean not null default false,
  constraint order_statuses_duration_check check (
    min_duration_seconds between 1 and 7
    and max_duration_seconds between 1 and 7
    and min_duration_seconds <= max_duration_seconds
  )
);

insert into public.order_statuses (
  id,
  code,
  name,
  position,
  min_duration_seconds,
  max_duration_seconds,
  is_terminal
)
values
  (1, 'processing', 'Обработка', 1, 1, 7, false),
  (2, 'accepted', 'Принят', 2, 1, 7, false),
  (3, 'preparing', 'Готовится', 3, 1, 7, false),
  (4, 'ready', 'Готов', 4, 1, 7, false),
  (5, 'completed', 'Выдан', 5, 1, 7, true)
on conflict (id) do update
set
  code = excluded.code,
  name = excluded.name,
  position = excluded.position,
  min_duration_seconds = excluded.min_duration_seconds,
  max_duration_seconds = excluded.max_duration_seconds,
  is_terminal = excluded.is_terminal;

alter table public.order_statuses enable row level security;

drop policy if exists "order_statuses_read" on public.order_statuses;
create policy "order_statuses_read"
on public.order_statuses
for select
to anon, authenticated
using (true);

revoke all on public.order_statuses from anon, authenticated;
grant select on public.order_statuses to anon, authenticated;

alter table public.orders
  add column if not exists status_id smallint;

alter table public.orders
  add column if not exists status_changed_at timestamptz;

alter table public.orders
  add column if not exists next_status_at timestamptz;

-- Existing orders were created before automatic statuses and may contain
-- arbitrary text. Keep them in history as completed orders.
update public.orders
set
  status_id = 5,
  status = 'Выдан',
  status_changed_at = coalesce(created_at, timezone('utc', now())),
  next_status_at = null
where status_id is null;

alter table public.orders
  alter column status_id set default 1,
  alter column status_id set not null,
  alter column status set default 'Обработка',
  alter column status_changed_at set default timezone('utc', now()),
  alter column status_changed_at set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'orders_status_id_fkey'
      and conrelid = 'public.orders'::regclass
  ) then
    alter table public.orders
      add constraint orders_status_id_fkey
      foreign key (status_id)
      references public.order_statuses(id);
  end if;
end
$$;

create index if not exists orders_next_status_at_idx
  on public.orders (next_status_at)
  where next_status_at is not null;

create or replace function public.sync_order_status()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  selected_status public.order_statuses%rowtype;
  duration_seconds integer;
begin
  if tg_op = 'INSERT' then
    new.status_id := 1;
  elsif new.status_id = old.status_id then
    -- The displayed status is derived from status_id and cannot be changed
    -- independently.
    new.status := old.status;
    new.status_changed_at := old.status_changed_at;
    new.next_status_at := old.next_status_at;
    return new;
  end if;

  select *
  into selected_status
  from public.order_statuses
  where id = new.status_id;

  if not found then
    raise exception 'Unknown order status id: %', new.status_id;
  end if;

  new.status := selected_status.name;
  new.status_changed_at := timezone('utc', clock_timestamp());

  if selected_status.is_terminal then
    new.next_status_at := null;
  else
    duration_seconds :=
      floor(
        random() * (
          selected_status.max_duration_seconds
          - selected_status.min_duration_seconds
          + 1
        )
      )::integer
      + selected_status.min_duration_seconds;

    new.next_status_at :=
      new.status_changed_at
      + make_interval(secs => duration_seconds);
  end if;

  return new;
end;
$$;

drop trigger if exists sync_order_status_trigger on public.orders;
create trigger sync_order_status_trigger
before insert or update of status_id, status
on public.orders
for each row
execute function public.sync_order_status();

create or replace function public.advance_due_order_statuses()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  updated_count integer;
begin
  with due_orders as (
    select
      orders.id,
      next_status.id as next_status_id
    from public.orders
    join public.order_statuses current_status
      on current_status.id = orders.status_id
    join lateral (
      select id
      from public.order_statuses
      where position > current_status.position
      order by position
      limit 1
    ) next_status on true
    where orders.next_status_at <= timezone('utc', clock_timestamp())
      and not current_status.is_terminal
    for update of orders skip locked
  )
  update public.orders
  set status_id = due_orders.next_status_id
  from due_orders
  where orders.id = due_orders.id;

  get diagnostics updated_count = row_count;
  return updated_count;
end;
$$;

revoke all on function public.advance_due_order_statuses() from public;

select cron.unschedule(jobid)
from cron.job
where jobname = 'automatic-order-statuses';

select cron.schedule(
  'automatic-order-statuses',
  '1 second',
  'select public.advance_due_order_statuses();'
);
