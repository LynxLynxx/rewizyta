-- keepalive() now writes a real table instead of returning a constant. The
-- staging project was paused on the free tier although the old no-op RPC
-- answered 200 twice a week, so a call that touches no table may not count as
-- activity. Same signature and grants, so the previous workflow keeps working.
--
-- The table is one row: when the last ping landed. RLS is enabled and forced
-- with no policy and the API roles have no grants; only keepalive() (security
-- definer) writes it.

create table public.keepalive (
  id boolean primary key default true check (id),
  pinged_at timestamptz not null default now()
);

comment on table public.keepalive is
  'One row: the last keepalive ping. Written only by keepalive(); RLS forced, no policy.';

alter table public.keepalive enable row level security;
alter table public.keepalive force row level security;
revoke all on table public.keepalive from anon, authenticated;

insert into public.keepalive default values;

create or replace function public.keepalive()
returns text
language sql
volatile
security definer
set search_path = ''
as $$
  -- `where id` because PostgREST's safeupdate rejects an UPDATE without WHERE.
  update public.keepalive set pinged_at = now() where id returning 'ok';
$$;
