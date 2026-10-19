-- pgTAP tests for supabase/migrations/*_keepalive_heartbeat.sql. Run with `supabase test db`.
begin;

select plan(3);

update public.keepalive set pinged_at = '2000-01-01';

set local role anon;
select is(public.keepalive(), 'ok', 'anon can call keepalive()');
select throws_ok('select * from public.keepalive', '42501', null, 'anon cannot read the table');
reset role;

select ok((select pinged_at > '2000-01-01' from public.keepalive), 'the call records the ping');

select * from finish();
rollback;
