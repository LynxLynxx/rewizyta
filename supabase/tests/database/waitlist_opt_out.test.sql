-- pgTAP tests for supabase/migrations/*_waitlist_opt_out.sql. Run with `supabase test db`.
begin;

select plan(6);

delete from public.waitlist_signups;

set local role service_role;

create temporary table result (step text primary key, body jsonb) on commit drop;
grant all on result to service_role;

insert into result values (
  'first',
  public.waitlist_signup(p_email => 'jan@example.com', p_phone => '+48601234567', p_consent => true)
);
select ok(public.waitlist_unsubscribe((select body ->> 'unsubscribe_token' from result where step = 'first')), 'the token unsubscribes');
select ok(
  (select phone is null and consented_at is not null from public.waitlist_signups),
  'unsubscribing drops the phone number and keeps the consent on record'
);

-- Someone types the unsubscribed address into the form again.
update public.waitlist_signups set signup_mailed_at = now() - interval '16 minutes';
insert into result values ('back', public.waitlist_signup(p_email => 'jan@example.com'));
select is((select body ->> 'mail' from result where step = 'back'), 'confirm', 'the address gets a new confirmation link');
select ok((select unsubscribed_at is not null from public.waitlist_signups), 'the opt-out holds until the link is used');

select ok(public.waitlist_confirm((select body ->> 'confirm_token' from result where step = 'back')), 'the new link confirms');
select ok(
  (select unsubscribed_at is null and confirmed_at is not null from public.waitlist_signups),
  'confirming opts the address in again'
);

select * from finish();
rollback;
