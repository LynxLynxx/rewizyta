-- Keeps the retention promise of /wypisz/ and /prywatnosc/ (docs/BACKEND_SCHEMA.md,
-- "Retention and purge"): an unsubscribed row is deleted 30 days after the
-- opt-out, and only a keyed hash of its address stays, so the opt-out outlives
-- the row. A daily pg_cron job does the deleting, and also drops rate_limits
-- windows older than a day, which until now went only on the next hit.
--
-- The 12-month rule ("everything 12 months after launch") needs a launch date
-- and comes with the launch mail.
--
-- Expand only: two tables, two functions, and waitlist_signup /
-- waitlist_confirm replaced in place with the same signatures and grants, so
-- the edge functions call them unchanged.

create extension if not exists pg_cron with schema pg_catalog;

-- ---------------------------------------------------------------------------
-- The opt-out record
-- ---------------------------------------------------------------------------

-- One row: the HMAC key, drawn once per project. Without it a hash of a known
-- address could be recomputed by anyone who sees the opt-out table.
create table public.waitlist_opt_out_key (
  id boolean primary key default true check (id),
  key bytea not null default extensions.gen_random_bytes(32)
);

comment on table public.waitlist_opt_out_key is
  'One row: the key for waitlist_email_hash(). Service role only (RLS forced, no policy).';

alter table public.waitlist_opt_out_key enable row level security;
alter table public.waitlist_opt_out_key force row level security;
revoke all on table public.waitlist_opt_out_key from anon, authenticated;

insert into public.waitlist_opt_out_key default values;

-- Addresses whose unsubscribed row was purged. Never the address itself.
create table public.waitlist_opt_outs (
  email_hash bytea primary key,
  created_at timestamptz not null default now()
);

comment on table public.waitlist_opt_outs is
  'HMAC of every purged unsubscribed address, so the opt-out holds. Service role only (RLS forced, no policy).';

alter table public.waitlist_opt_outs enable row level security;
alter table public.waitlist_opt_outs force row level security;
revoke all on table public.waitlist_opt_outs from anon, authenticated;

-- HMAC-SHA256 of a stored (trimmed, lower-cased) address.
create function public.waitlist_email_hash(p_email text)
returns bytea
language sql
stable
security invoker
set search_path = ''
as $$
  select extensions.hmac(convert_to(p_email, 'UTF8'), key, 'sha256')
  from public.waitlist_opt_out_key;
$$;

-- ---------------------------------------------------------------------------
-- The daily purge
-- ---------------------------------------------------------------------------

create function public.waitlist_purge()
returns void
language sql
volatile
security invoker
set search_path = ''
as $$
  with purged as (
    delete from public.waitlist_signups
    where unsubscribed_at <= now() - interval '30 days'
    returning email
  )
  insert into public.waitlist_opt_outs (email_hash)
  select public.waitlist_email_hash(email) from purged
  on conflict (email_hash) do nothing;

  delete from public.rate_limits where window_start < now() - interval '1 day';
$$;

-- 02:30 UTC. Runs as the migration's role (postgres); a job of the same name
-- is replaced, not duplicated.
select cron.schedule('waitlist-purge', '30 2 * * *', 'select public.waitlist_purge()');

-- ---------------------------------------------------------------------------
-- Sign-up and confirmation read the opt-out record
-- ---------------------------------------------------------------------------

-- Adds an address to the list, or finds it again.
--
-- Returns {status, mail, promo_code, confirm_token, unsubscribe_token}:
--   status  created       new row
--           pending       known, not confirmed yet
--           confirmed     known and confirmed
--           resubscribed  had unsubscribed (its row may be purged since);
--                         needs a fresh confirmation
--   mail    confirm       send the double-opt-in mail (confirm_token is set)
--           code          send a reminder with the promo code
--           null          throttled: a mail went out less than 15 minutes ago
--
-- The caller shows the promo code only for 'created'; for a known address it
-- goes by mail, so typing someone else's address never reveals their code.
-- For the same reason a repeat changes none of the stored data (answers,
-- phone, consent, trade, source): anyone can type any address. It only decides
-- which mail to send, and a re-subscription stays opted out until its new link
-- is confirmed (waitlist_confirm lifts the opt-out).
--
-- A purged address comes back as a new row that is already unsubscribed, so it
-- behaves as it did before the purge; its 30 days start again, so an
-- unconfirmed comeback is purged again.
create or replace function public.waitlist_signup(
  p_email text,
  p_trade text default null,
  p_source text default null,
  p_answers jsonb default null,
  p_phone text default null,
  p_consent boolean default false
)
returns jsonb
language plpgsql
volatile
security invoker
set search_path = ''
as $$
declare
  v_email constant text := lower(trim(p_email));
  v_consented_at constant timestamptz := case when p_consent then now() end;
  v_opted_out constant boolean := exists (
    select 1 from public.waitlist_opt_outs where email_hash = public.waitlist_email_hash(v_email)
  );
  v_row public.waitlist_signups;
  v_status text;
  v_mail text;
begin
  for attempt in 1..5 loop
    begin
      insert into public.waitlist_signups (
        email, trade, source, answers, phone, consented_at,
        confirm_token, signup_mailed_at, unsubscribe_token, promo_code, unsubscribed_at
      )
      values (
        v_email, p_trade, p_source, p_answers, case when p_consent then p_phone end, v_consented_at,
        public.waitlist_random_token(), now(), public.waitlist_random_token(), public.waitlist_promo_code(),
        case when v_opted_out then now() end
      )
      on conflict (email) do nothing
      returning * into v_row;
      exit;
    exception when unique_violation then
      -- The e-mail conflict is handled above, so this is a promo code
      -- collision (about 1 in 10^11 per row). Draw again.
      if attempt = 5 then
        raise;
      end if;
    end;
  end loop;

  if v_row.id is not null then
    return jsonb_build_object(
      'status', case when v_opted_out then 'resubscribed' else 'created' end,
      'mail', 'confirm',
      'promo_code', v_row.promo_code,
      'confirm_token', v_row.confirm_token,
      'unsubscribe_token', v_row.unsubscribe_token
    );
  end if;

  select * into strict v_row from public.waitlist_signups where email = v_email for update;

  if v_row.unsubscribed_at is not null then
    v_status := 'resubscribed';
  elsif v_row.confirmed_at is not null then
    v_status := 'confirmed';
  else
    v_status := 'pending';
  end if;

  if v_row.signup_mailed_at is null or v_row.signup_mailed_at <= now() - interval '15 minutes' then
    v_mail := case when v_status = 'confirmed' then 'code' else 'confirm' end;
  end if;

  update public.waitlist_signups
  set
    confirm_token = case
      when v_mail = 'confirm' then coalesce(confirm_token, public.waitlist_random_token())
      else confirm_token
    end,
    signup_mailed_at = case when v_mail is not null then now() else signup_mailed_at end
  where id = v_row.id
  returning * into v_row;

  return jsonb_build_object(
    'status', v_status,
    'mail', v_mail,
    'promo_code', v_row.promo_code,
    'confirm_token', case when v_mail = 'confirm' then v_row.confirm_token end,
    'unsubscribe_token', v_row.unsubscribe_token
  );
end;
$$;

-- Double opt-in. True when the token matched; a used or unknown token returns
-- false. Unsubscribing clears the token, so a token on an unsubscribed row was
-- issued by a re-subscription, and using it opts the address in again, which
-- also ends the opt-out record of a purged row.
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
    returning email
  ), forgotten as (
    delete from public.waitlist_opt_outs
    where email_hash in (select public.waitlist_email_hash(email) from confirmed)
  )
  select exists (select 1 from confirmed);
$$;

-- waitlist_email_hash runs inside the service-role functions; the purge runs
-- only from cron.
revoke all on function public.waitlist_email_hash(text) from public, anon, authenticated;
revoke all on function public.waitlist_purge() from public, anon, authenticated, service_role;
grant execute on function public.waitlist_email_hash(text) to service_role;
