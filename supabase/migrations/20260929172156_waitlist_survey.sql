-- The waitlist page asks seven short questions, an optional phone number for a
-- call-back and a consent tick box (docs/DATABASE.md, "waitlist_signups").
--
-- Expand only: three nullable columns, and waitlist_signup() gains three
-- parameters with defaults, so a caller that sends {email, trade, source}
-- keeps working unchanged.

alter table public.waitlist_signups
  -- Survey answers as the waitlist-signup function validated them (see
  -- functions/_shared/waitlist/survey.ts): option keys, never free-form labels,
  -- plus a short text for "other".
  add column answers jsonb
    check (jsonb_typeof(answers) = 'object' and length(answers::text) <= 4000),
  -- E.164. Given only for a call-back, and only with consent.
  add column phone text
    check (phone ~ '^\+[1-9][0-9]{7,14}$'),
  -- When the visitor last ticked "contact me about Rewizyta" on the page. The
  -- double opt-in (confirmed_at) is still what allows a second mail.
  add column consented_at timestamptz,
  -- A phone number is kept only under that consent.
  add constraint waitlist_signups_phone_needs_consent check (phone is null or consented_at is not null);

-- A new signature cannot replace the old one in place; the defaults keep every
-- existing named-argument call (PostgREST RPC) resolving to the new function.
drop function public.waitlist_signup(text, text, text);

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
-- For the same reason a repeat changes none of the stored data (answers,
-- phone, consent, trade, source): anyone can type any address. It only decides
-- which mail to send, and a re-subscription stays opted out until its new link
-- is confirmed (waitlist_confirm lifts the opt-out).
create function public.waitlist_signup(
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
  v_row public.waitlist_signups;
  v_status text;
  v_mail text;
begin
  for attempt in 1..5 loop
    begin
      insert into public.waitlist_signups (
        email, trade, source, answers, phone, consented_at,
        confirm_token, signup_mailed_at, unsubscribe_token, promo_code
      )
      values (
        v_email, p_trade, p_source, p_answers, case when p_consent then p_phone end, v_consented_at,
        public.waitlist_random_token(), now(), public.waitlist_random_token(), public.waitlist_promo_code()
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

-- Service role only, like the function it replaces.
revoke all on function public.waitlist_signup(text, text, text, jsonb, text, boolean) from public, anon, authenticated;
grant execute on function public.waitlist_signup(text, text, text, jsonb, text, boolean) to service_role;
