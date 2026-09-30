-- The waitlist page promises "3 miesiące za darmo", so every code it hands out
-- is worth a 90-day trial (docs/DATABASE.md, "waitlist_signups").
--
-- Expand only: a column default and a backfill. waitlist_signup() does not
-- name the column, so both of its signatures pick the default up unchanged. A
-- later campaign with another reward changes the default in its own migration.

alter table public.waitlist_signups
  alter column promo_reward set default 'trial_90d';

-- Every earlier sign-up came from the same page and the same promise.
update public.waitlist_signups
set promo_reward = 'trial_90d'
where promo_reward is null;
