-- An opt-out holds until the owner of the address acts (docs/DATABASE.md,
-- "waitlist_signups").
--
-- waitlist_signup no longer lifts an opt-out when someone types an unsubscribed
-- address into the form (*_waitlist_survey.sql): the address gets a new
-- confirmation link and stays unsubscribed. Using that link is what opts it in
-- again, so waitlist_confirm now clears unsubscribed_at. Unsubscribing withdraws
-- the consent the phone number was given under, so the number goes with it.
--
-- Same signatures and grants (create or replace keeps them); the edge
-- functions call both unchanged.

-- Double opt-in. True when the token matched; a used or unknown token returns
-- false. Unsubscribing clears the token, so a token on an unsubscribed row was
-- issued by a re-subscription, and using it opts the address in again.
create or replace function public.waitlist_confirm(p_token text)
returns boolean
language sql
volatile
security invoker
set search_path = ''
as $$
  with confirmed as (
    update public.waitlist_signups
    set confirmed_at = now(), confirm_token = null, unsubscribed_at = null
    where confirm_token = p_token
    returning 1
  )
  select exists (select 1 from confirmed);
$$;

-- Opt-out. Idempotent: an already unsubscribed row still returns true. The
-- row stays as the record of the opt-out; the phone number does not.
create or replace function public.waitlist_unsubscribe(p_token text)
returns boolean
language sql
volatile
security invoker
set search_path = ''
as $$
  with unsubscribed as (
    update public.waitlist_signups
    set unsubscribed_at = coalesce(unsubscribed_at, now()), confirm_token = null, phone = null
    where unsubscribe_token = p_token
    returning 1
  )
  select exists (select 1 from unsubscribed);
$$;
