-- keepalive(): a no-op RPC that the scheduled GitHub workflow calls so a
-- free-tier project counts as active. Exposed to anon on purpose; it reveals
-- nothing and touches no table. Safe to leave in place on Pro or self-hosted.
create or replace function public.keepalive()
returns text
language sql
stable
security invoker
set search_path = ''
as $$
  select 'ok';
$$;

revoke all on function public.keepalive() from public;
grant execute on function public.keepalive() to anon, authenticated;
