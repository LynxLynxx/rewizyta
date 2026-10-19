-- pgTAP tests for supabase/migrations/*_waitlist_retention.sql. Run with `supabase test db`.
begin;

select plan(15);

select ok(
  (select bool_and(relrowsecurity and relforcerowsecurity) from pg_class
   where oid in ('public.waitlist_opt_outs'::regclass, 'public.waitlist_opt_out_key'::regclass)),
  'RLS is enabled and forced on both new tables'
);
select ok(
  not has_table_privilege('anon', 'public.waitlist_opt_outs', 'select')
    and not has_table_privilege('authenticated', 'public.waitlist_opt_out_key', 'select'),
  'the API roles cannot read the opt-outs or the key'
);
select ok(
  not has_function_privilege('anon', 'public.waitlist_purge()', 'execute')
    and not has_function_privilege('service_role', 'public.waitlist_purge()', 'execute'),
  'only cron runs the purge'
);
select is(
  (select schedule from cron.job where jobname = 'waitlist-purge'),
  '30 2 * * *',
  'the purge runs daily'
);

delete from public.waitlist_signups;
delete from public.waitlist_opt_outs;
delete from public.rate_limits;

set local role service_role;
select public.waitlist_signup(p_email => 'gone@example.com');
select public.waitlist_signup(p_email => 'recent@example.com');
select public.waitlist_signup(p_email => 'stays@example.com');
reset role;

update public.waitlist_signups set unsubscribed_at = now() - interval '31 days' where email = 'gone@example.com';
update public.waitlist_signups set unsubscribed_at = now() - interval '29 days' where email = 'recent@example.com';
insert into public.rate_limits (key, window_start) values
  ('old', now() - interval '25 hours'),
  ('new', now() - interval '1 hour');

select public.waitlist_purge();

select is(
  (select array_agg(email order by email) from public.waitlist_signups),
  array['recent@example.com', 'stays@example.com'],
  'only a row unsubscribed more than 30 days ago is deleted'
);
select is((select count(*)::int from public.waitlist_opt_outs), 1, 'the purged address leaves one opt-out record');
select is(
  (select email_hash from public.waitlist_opt_outs),
  public.waitlist_email_hash('gone@example.com'),
  'the record is the keyed hash of the address'
);
select isnt(
  public.waitlist_email_hash('gone@example.com'),
  extensions.digest('gone@example.com', 'sha256'),
  'the hash is keyed, not a plain SHA-256'
);
select is(
  (select array_agg(key) from public.rate_limits),
  array['new'],
  'rate-limit windows older than a day are deleted'
);

select public.waitlist_purge();
select is((select count(*)::int from public.waitlist_opt_outs), 1, 'a second run changes nothing');

-- The purged address is typed into the form again.
set local role service_role;
create temporary table result (step text primary key, body jsonb) on commit drop;
insert into result values ('back', public.waitlist_signup(p_email => ' GONE@example.com '));
insert into result values ('fresh', public.waitlist_signup(p_email => 'fresh@example.com'));

select is((select body ->> 'status' from result where step = 'back'), 'resubscribed', 'a purged address comes back as a re-subscription');
select ok(
  (select unsubscribed_at is not null and confirmed_at is null from public.waitlist_signups where email = 'gone@example.com'),
  'the opt-out holds until the new link is used'
);
select is((select body ->> 'status' from result where step = 'fresh'), 'created', 'a new address is still created');

select ok(public.waitlist_confirm((select body ->> 'confirm_token' from result where step = 'back')), 'the new link confirms');
reset role;
select ok(
  (select unsubscribed_at is null from public.waitlist_signups where email = 'gone@example.com')
    and not exists (select 1 from public.waitlist_opt_outs),
  'confirming opts the address in again and ends its opt-out record'
);

select * from finish();
rollback;
