-- The pre-launch waitlist: the mailing list, its promo codes and a small rate
-- limiter for the public edge functions (docs/DATABASE.md, "waitlist_signups";
-- docs/ARCHITECTURE.md, "E-mail: auth, waitlist and unsubscribe").
--
-- Nobody but the service role touches these tables: RLS is enabled and forced
-- with no policy, and the API roles lose every grant. The waitlist-* edge
-- functions call the service-role-only functions below, which keep each step
-- (sign-up, confirmation, unsubscribe) to one atomic statement.

-- ---------------------------------------------------------------------------
-- waitlist_signups
-- ---------------------------------------------------------------------------

create table public.waitlist_signups (
  id uuid primary key default gen_random_uuid(),
  -- Stored lower-cased, so the plain unique constraint is case-insensitive.
  email text not null unique
    check (email = lower(email) and length(email) between 3 and 254 and position('@' in email) > 1),
  trade text check (trade in ('chimney', 'gas', 'boiler', 'other')),
  source text check (length(source) <= 200),
  -- 256-bit random, base64url. Cleared on confirmation.
  confirm_token text unique,
  -- When the last confirmation or code-reminder mail went out. Throttles repeat sign-ups.
  signup_mailed_at timestamptz,
  confirmed_at timestamptz,
  -- 256-bit random, base64url. Lives as long as the row; every mail links to it.
  unsubscribe_token text not null unique,
  unsubscribed_at timestamptz,
  last_mailed_at timestamptz,
  promo_code text not null unique,
  -- Chosen per campaign before launch; null means "a launch bonus, to be announced".
  promo_reward text check (promo_reward in ('sms_100', 'trial_90d')),
  redeemed_at timestamptz,
  redeemed_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now()
);

comment on table public.waitlist_signups is
  'Pre-launch mailing list. Service role only (RLS forced, no policy). See docs/DATABASE.md.';

alter table public.waitlist_signups enable row level security;
alter table public.waitlist_signups force row level security;
revoke all on table public.waitlist_signups from anon, authenticated;

-- ---------------------------------------------------------------------------
-- rate_limits: fixed-window counters for public endpoints
-- ---------------------------------------------------------------------------

create table public.rate_limits (
  -- '<endpoint>:<hmac of the client ip>'. Never the address itself.
  key text not null,
  window_start timestamptz not null,
  hits integer not null default 1,
  primary key (key, window_start)
);

comment on table public.rate_limits is
  'Hit counters keyed by a keyed hash of the caller. Rows older than a day are deleted on the next hit.';

alter table public.rate_limits enable row level security;
alter table public.rate_limits force row level security;
revoke all on table public.rate_limits from anon, authenticated;

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

-- 32 random bytes as unpadded base64url (43 characters).
create function public.waitlist_random_token()
returns text
language sql
volatile
security invoker
set search_path = ''
as $$
  select rtrim(translate(encode(extensions.gen_random_bytes(32), 'base64'), '+/', '-_'), '=');
$$;

-- REWI-XXXX-XXXX from Crockford base32 minus the vowels A and E (30 symbols,
-- 30^8 codes), so a code is easy to read aloud and never spells a word.
-- Rejection sampling keeps every symbol equally likely.
create function public.waitlist_promo_code()
returns text
language plpgsql
volatile
security invoker
set search_path = ''
as $$
declare
  alphabet constant text := '0123456789BCDFGHJKMNPQRSTVWXYZ';
  code text := '';
  b integer;
begin
  while length(code) < 8 loop
    b := get_byte(extensions.gen_random_bytes(1), 0);
    if b < 240 then
      code := code || substr(alphabet, b % 30 + 1, 1);
    end if;
  end loop;
  return 'REWI-' || substr(code, 1, 4) || '-' || substr(code, 5, 4);
end;
$$;

-- ---------------------------------------------------------------------------
-- Operations called by the edge functions
-- ---------------------------------------------------------------------------

-- Adds an address to the list, or finds it again.
--
-- Returns {status, mail, promo_code, confirm_token, unsubscribe_token}:
--   status  created       new row
--           pending       known, not confirmed yet
--           confirmed     known and confirmed
--           resubscribed  had unsubscribed; needs a fresh confirmation
--   mail    confirm       send the double-opt-in mail (confirm_token is set)
--           code          send a reminder with the promo code
--           null          throttled: a mail went out less than 15 minutes ago
--
-- The caller shows the promo code only for 'created'; for a known address it
-- goes by mail, so typing someone else's address never reveals their code.
create function public.waitlist_signup(p_email text, p_trade text default null, p_source text default null)
returns jsonb
language plpgsql
volatile
security invoker
set search_path = ''
as $$
declare
  v_email constant text := lower(trim(p_email));
  v_row public.waitlist_signups;
  v_status text;
  v_mail text;
begin
  for attempt in 1..5 loop
    begin
      insert into public.waitlist_signups (
        email, trade, source, confirm_token, signup_mailed_at, unsubscribe_token, promo_code
      )
      values (
        v_email, p_trade, p_source, public.waitlist_random_token(), now(),
        public.waitlist_random_token(), public.waitlist_promo_code()
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
      'status', 'created',
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
    trade = coalesce(trade, p_trade),
    source = coalesce(source, p_source),
    -- Re-subscribing starts the double opt-in again; consent must be fresh.
    unsubscribed_at = case when v_status = 'resubscribed' and v_mail is not null then null else unsubscribed_at end,
    confirmed_at = case when v_status = 'resubscribed' and v_mail is not null then null else confirmed_at end,
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

-- Double opt-in. True when the token matched a pending row; a used or unknown
-- token returns false.
create function public.waitlist_confirm(p_token text)
returns boolean
language sql
volatile
security invoker
set search_path = ''
as $$
  with confirmed as (
    update public.waitlist_signups
    set confirmed_at = now(), confirm_token = null
    where confirm_token = p_token and unsubscribed_at is null
    returning 1
  )
  select exists (select 1 from confirmed);
$$;

-- Opt-out. Idempotent: an already unsubscribed row still returns true. The
-- row stays as the record of the opt-out.
create function public.waitlist_unsubscribe(p_token text)
returns boolean
language sql
volatile
security invoker
set search_path = ''
as $$
  with unsubscribed as (
    update public.waitlist_signups
    set unsubscribed_at = coalesce(unsubscribed_at, now()), confirm_token = null
    where unsubscribe_token = p_token
    returning 1
  )
  select exists (select 1 from unsubscribed);
$$;

-- Counts one hit for p_key in the current fixed window and says whether the
-- caller is still within p_max hits. Prunes day-old windows as it goes.
create function public.rate_limit_hit(p_key text, p_max integer, p_window interval)
returns boolean
language plpgsql
volatile
security invoker
set search_path = ''
as $$
declare
  v_hits integer;
begin
  delete from public.rate_limits where window_start < now() - interval '1 day';

  insert into public.rate_limits as r (key, window_start)
  values (p_key, date_bin(p_window, now(), timestamptz '2000-01-01 00:00:00+00'))
  on conflict (key, window_start) do update set hits = r.hits + 1
  returning r.hits into v_hits;

  return v_hits <= p_max;
end;
$$;

-- Service role only. Postgres grants EXECUTE to PUBLIC by default and Supabase
-- adds anon and authenticated, so take all three away.
revoke all on function public.waitlist_random_token() from public, anon, authenticated;
revoke all on function public.waitlist_promo_code() from public, anon, authenticated;
revoke all on function public.waitlist_signup(text, text, text) from public, anon, authenticated;
revoke all on function public.waitlist_confirm(text) from public, anon, authenticated;
revoke all on function public.waitlist_unsubscribe(text) from public, anon, authenticated;
revoke all on function public.rate_limit_hit(text, integer, interval) from public, anon, authenticated;

grant execute on function public.waitlist_random_token() to service_role;
grant execute on function public.waitlist_promo_code() to service_role;
grant execute on function public.waitlist_signup(text, text, text) to service_role;
grant execute on function public.waitlist_confirm(text) to service_role;
grant execute on function public.waitlist_unsubscribe(text) to service_role;
grant execute on function public.rate_limit_hit(text, integer, interval) to service_role;
