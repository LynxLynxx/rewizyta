-- pgTAP tests for supabase/migrations/*_waitlist_promo_reward.sql. Run with `supabase test db`.
begin;

select plan(4);

delete from public.waitlist_signups;

select col_default_is(
  'public', 'waitlist_signups', 'promo_reward', 'trial_90d',
  'the page promises three free months, so a new code is a 90-day trial'
);

set local role service_role;

select public.waitlist_signup(p_email => 'jan@example.com', p_answers => '{"trade": ["chimney"]}'::jsonb, p_consent => true);
select is(
  (select promo_reward from public.waitlist_signups where email = 'jan@example.com'),
  'trial_90d',
  'a sign-up from the page gets the trial'
);

-- The previous edge function's call: three named arguments.
select public.waitlist_signup(p_email => 'old@example.com', p_trade => 'gas', p_source => 'fb');
select is(
  (select promo_reward from public.waitlist_signups where email = 'old@example.com'),
  'trial_90d',
  'a sign-up through the previous arguments gets the trial too'
);

reset role;

select throws_ok(
  $$ update public.waitlist_signups set promo_reward = 'free_forever' where email = 'jan@example.com' $$,
  '23514', null, 'only the known rewards are allowed'
);

select * from finish();
rollback;
