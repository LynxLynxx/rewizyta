-- pgTAP tests for supabase/migrations/*_waitlist_survey.sql. Run with `supabase test db`.
begin;

select plan(17);

delete from public.waitlist_signups;

select ok(
  not has_function_privilege('authenticated', 'public.waitlist_signup(text, text, text, jsonb, text, boolean)', 'execute'),
  'authenticated cannot execute the new signature'
);

set local role anon;
select throws_ok(
  $$ select public.waitlist_signup(p_email => 'a@example.com', p_consent => true) $$,
  '42501', null, 'anon cannot call waitlist_signup with the new arguments'
);
reset role;

set local role service_role;

-- The previous edge function's call: three named arguments.
select is(
  public.waitlist_signup(p_email => 'old@example.com', p_trade => 'gas', p_source => 'fb') ->> 'status',
  'created',
  'a call with the previous arguments still works'
);
select ok(
  (select answers is null and phone is null and consented_at is null from public.waitlist_signups where email = 'old@example.com'),
  'the previous call stores no answers, phone or consent'
);

select is(
  public.waitlist_signup(
    p_email => 'jan@example.com',
    p_answers => '{"trade": ["chimney"], "clients": "50_200"}'::jsonb,
    p_phone => '+48601234567',
    p_consent => true
  ) ->> 'status',
  'created',
  'a sign-up with the survey is created'
);
select is(
  (select answers from public.waitlist_signups where email = 'jan@example.com'),
  '{"trade": ["chimney"], "clients": "50_200"}'::jsonb,
  'the answers are stored'
);
select is((select phone from public.waitlist_signups where email = 'jan@example.com'), '+48601234567', 'the phone is stored');
select is(
  (select consented_at from public.waitlist_signups where email = 'jan@example.com'),
  now(),
  'the consent is time-stamped'
);

select public.waitlist_signup(
  p_email => 'jan@example.com',
  p_answers => '{"clients": "over_500"}'::jsonb,
  p_phone => '+493012345678'
);
select ok(
  (select answers ->> 'clients' = '50_200' and phone = '+48601234567' from public.waitlist_signups where email = 'jan@example.com'),
  'a repeat does not overwrite the first answers or phone'
);
select isnt(
  (select consented_at from public.waitlist_signups where email = 'jan@example.com'),
  null,
  'a repeat without the tick keeps the earlier consent'
);

-- Anyone can type any address: a repeat must not write into the row.
select public.waitlist_signup(
  p_email => 'old@example.com',
  p_answers => '{"trade": ["gas"]}'::jsonb,
  p_phone => '+48601234567',
  p_consent => true
);
select ok(
  (select answers is null and phone is null and consented_at is null from public.waitlist_signups where email = 'old@example.com'),
  'a repeat does not fill in answers, a phone number or consent'
);

-- Coming back after an opt-out changes nothing until the new link is used.
update public.waitlist_signups set unsubscribed_at = now(), signup_mailed_at = now() - interval '16 minutes'
where email = 'jan@example.com';
select public.waitlist_signup(p_email => 'jan@example.com');
select ok(
  (select unsubscribed_at is not null and consented_at is not null from public.waitlist_signups where email = 'jan@example.com'),
  'a re-subscription keeps the opt-out and the earlier consent'
);

select public.waitlist_signup(p_email => 'ola@example.com', p_phone => '+48601234567');
select is(
  (select phone from public.waitlist_signups where email = 'ola@example.com'),
  null,
  'a phone number without consent is not stored'
);

reset role;

select throws_ok(
  $$ update public.waitlist_signups set phone = '601234567' where email = 'jan@example.com' $$,
  '23514', null, 'a phone number that is not E.164 is refused'
);
select throws_ok(
  $$ update public.waitlist_signups set consented_at = null where email = 'jan@example.com' $$,
  '23514', null, 'a phone number needs consent'
);
select throws_ok(
  $$ update public.waitlist_signups set answers = '["chimney"]'::jsonb where email = 'jan@example.com' $$,
  '23514', null, 'answers must be an object'
);
select throws_ok(
  $$ update public.waitlist_signups set answers = jsonb_build_object('x', repeat('y', 5000)) where email = 'jan@example.com' $$,
  '23514', null, 'answers are capped in size'
);

select * from finish();
rollback;
