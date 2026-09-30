-- pgTAP tests for supabase/migrations/*_waitlist.sql. Run with `supabase test db`.
-- Everything runs in one transaction, so now() is constant: throttling is
-- exercised by moving signup_mailed_at into the past.
begin;

select plan(37);

-- Start from empty tables whatever the local database holds; rolled back at the end.
delete from public.waitlist_signups;
delete from public.rate_limits;

-- ---------------------------------------------------------------------------
-- Locked down
-- ---------------------------------------------------------------------------

select ok(
  (select relrowsecurity and relforcerowsecurity from pg_class where oid = 'public.waitlist_signups'::regclass),
  'waitlist_signups has RLS enabled and forced'
);
select ok(
  (select relrowsecurity and relforcerowsecurity from pg_class where oid = 'public.rate_limits'::regclass),
  'rate_limits has RLS enabled and forced'
);
select is(
  (select count(*)::int from pg_policies where tablename in ('waitlist_signups', 'rate_limits')),
  0,
  'no policy opens either table to the API roles'
);

set local role anon;
select throws_ok(
  $$ select * from public.waitlist_signups $$,
  '42501', null, 'anon cannot read waitlist_signups'
);
select throws_ok(
  $$ select public.waitlist_signup('a@example.com') $$,
  '42501', null, 'anon cannot call waitlist_signup'
);
select throws_ok(
  $$ select public.waitlist_confirm('x') $$,
  '42501', null, 'anon cannot call waitlist_confirm'
);
select throws_ok(
  $$ select public.rate_limit_hit('k', 1, interval '1 minute') $$,
  '42501', null, 'anon cannot call rate_limit_hit'
);
reset role;

set local role authenticated;
select throws_ok(
  $$ insert into public.waitlist_signups (email, unsubscribe_token, promo_code) values ('a@example.com', 'u', 'p') $$,
  '42501', null, 'authenticated cannot write waitlist_signups'
);
select throws_ok(
  $$ select public.waitlist_unsubscribe('x') $$,
  '42501', null, 'authenticated cannot call waitlist_unsubscribe'
);
reset role;

-- ---------------------------------------------------------------------------
-- Sign-up
-- ---------------------------------------------------------------------------

set local role service_role;

create temporary table result (step text primary key, body jsonb) on commit drop;
grant all on result to service_role;

insert into result values ('first', public.waitlist_signup('  JAN.Kowalski@example.com ', 'chimney', 'fb'));

select is((select body ->> 'status' from result where step = 'first'), 'created', 'a new address is created');
select is((select body ->> 'mail' from result where step = 'first'), 'confirm', 'a new address gets the confirmation mail');
select matches(
  (select body ->> 'promo_code' from result where step = 'first'),
  '^REWI-[0-9BCDFGHJKMNPQRSTVWXYZ]{4}-[0-9BCDFGHJKMNPQRSTVWXYZ]{4}$',
  'the promo code is REWI-XXXX-XXXX without vowels'
);
select matches(
  (select body ->> 'confirm_token' from result where step = 'first'),
  '^[A-Za-z0-9_-]{43}$',
  'the confirm token is 32 bytes of base64url'
);
select is(
  (select email || '|' || trade || '|' || source from public.waitlist_signups),
  'jan.kowalski@example.com|chimney|fb',
  'the address is stored trimmed and lower-cased with its trade and source'
);

insert into result values ('again', public.waitlist_signup('Jan.KOWALSKI@example.com', 'gas'));

select is((select body ->> 'status' from result where step = 'again'), 'pending', 'the same address in another case is found again');
select is((select body -> 'mail' from result where step = 'again'), 'null'::jsonb, 'a repeat within 15 minutes sends nothing');
select is((select count(*)::int from public.waitlist_signups), 1, 'a repeat does not add a row');
select is((select trade from public.waitlist_signups), 'chimney', 'a repeat keeps the first trade');

update public.waitlist_signups set signup_mailed_at = now() - interval '16 minutes';
insert into result values ('resend', public.waitlist_signup('jan.kowalski@example.com'));

select is((select body ->> 'mail' from result where step = 'resend'), 'confirm', 'after 15 minutes the confirmation is sent again');
select is(
  (select body ->> 'confirm_token' from result where step = 'resend'),
  (select body ->> 'confirm_token' from result where step = 'first'),
  'the resent mail carries the same token, so the first link keeps working'
);

-- ---------------------------------------------------------------------------
-- Confirmation
-- ---------------------------------------------------------------------------

select ok(public.waitlist_confirm((select body ->> 'confirm_token' from result where step = 'first')), 'the token confirms');
select ok((select confirmed_at is not null and confirm_token is null from public.waitlist_signups), 'confirmed_at is set and the token cleared');
select ok(not public.waitlist_confirm((select body ->> 'confirm_token' from result where step = 'first')), 'a used token does not confirm again');
select ok(not public.waitlist_confirm('unknown'), 'an unknown token does not confirm');

update public.waitlist_signups set signup_mailed_at = now() - interval '16 minutes';
insert into result values ('confirmed', public.waitlist_signup('jan.kowalski@example.com'));

select is((select body ->> 'status' from result where step = 'confirmed'), 'confirmed', 'a confirmed address is reported as confirmed');
select is((select body ->> 'mail' from result where step = 'confirmed'), 'code', 'a confirmed address gets its code by mail');

-- ---------------------------------------------------------------------------
-- Unsubscribe and coming back
-- ---------------------------------------------------------------------------

select ok(public.waitlist_unsubscribe((select body ->> 'unsubscribe_token' from result where step = 'first')), 'the token unsubscribes');
select ok(public.waitlist_unsubscribe((select body ->> 'unsubscribe_token' from result where step = 'first')), 'unsubscribing twice is fine');
select ok(not public.waitlist_unsubscribe('unknown'), 'an unknown token unsubscribes nobody');
select ok((select unsubscribed_at is not null from public.waitlist_signups), 'unsubscribed_at is set');

update public.waitlist_signups set signup_mailed_at = now() - interval '16 minutes';
insert into result values ('back', public.waitlist_signup('jan.kowalski@example.com'));

select is((select body ->> 'status' from result where step = 'back'), 'resubscribed', 'signing up after an opt-out is a re-subscription');
select ok(
  (select unsubscribed_at is not null and confirm_token is not null from public.waitlist_signups),
  'a re-subscription stays opted out until its new link is confirmed'
);
select ok(public.waitlist_confirm((select body ->> 'confirm_token' from result where step = 'back')), 'the new link confirms');
select ok(
  (select unsubscribed_at is null and confirmed_at is not null from public.waitlist_signups),
  'confirming the new link opts the address in again'
);

-- ---------------------------------------------------------------------------
-- Rate limit
-- ---------------------------------------------------------------------------

select ok(public.rate_limit_hit('test:ip', 2, interval '10 minutes'), 'first hit passes');
select ok(public.rate_limit_hit('test:ip', 2, interval '10 minutes'), 'second hit passes');
select ok(not public.rate_limit_hit('test:ip', 2, interval '10 minutes'), 'third hit in the window is refused');

reset role;

select * from finish();
rollback;
