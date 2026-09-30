import { type EmailGateway, EmailGatewayError } from '../_shared/email/email_gateway.ts';
import { corsHeaders, isForeignOrigin, json, readJsonObject } from '../_shared/http.ts';
import type { WaitlistConfig } from '../_shared/waitlist/config.ts';
import { codeMail, confirmationMail, mailLinks } from '../_shared/waitlist/mails.ts';
import { normalizePhone } from '../_shared/waitlist/phone.ts';
import { parseAnswers } from '../_shared/waitlist/survey.ts';
import { type SignupResult, type Trade, trades, type WaitlistStore } from '../_shared/waitlist/waitlist_store.ts';

export interface SignupDeps {
  store: WaitlistStore;
  email: EmailGateway;
  config: WaitlistConfig;
  /** Rate-limit key of the caller (see `client_key.ts`). */
  clientKey: (request: Request) => Promise<string>;
  log?: (message: string) => void;
}

/** What the page receives. The promo code only for a new address. */
export type SignupResponse =
  | { status: 'created'; promoCode: string; mailSent: boolean }
  | { status: 'pending' | 'confirmed' | 'resubscribed'; mailSent: boolean };

/** Per caller: enough for a typo and a retry, too few to spray addresses. */
export const perClientLimit = { max: 5, windowSeconds: 10 * 60 };

/**
 * Everyone together. The caller key rests on a forgeable header, so this cap
 * is what keeps a flood from burning the mail vendor's free daily quota.
 */
export const overallLimit = { max: 120, windowSeconds: 60 * 60 };

const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

/**
 * `POST {email, trade?, source?, answers?, phone?, consent?, website?}` from
 * the waitlist page. `answers` are the survey's option keys (`survey.ts`); a
 * phone number is taken only with `consent: true`. `website` is a decoy field
 * hidden from people; a filled one gets a fake success and nothing is stored
 * or sent.
 */
export function createSignupHandler(deps: SignupDeps): (request: Request) => Promise<Response> {
  const log = deps.log ?? console.error;
  const { config, store } = deps;

  return async (request) => {
    const cors = corsHeaders(request, config.allowedOrigins);
    if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers: cors });
    if (request.method !== 'POST') return json({ error: 'method_not_allowed' }, 405, cors);
    if (isForeignOrigin(request, config.allowedOrigins)) return json({ error: 'forbidden' }, 403);

    const body = await readJsonObject(request);
    if (body === null) return json({ error: 'invalid_request' }, 400, cors);

    if (typeof body.website === 'string' && body.website !== '') {
      return json({ status: 'pending', mailSent: true } satisfies SignupResponse, 200, cors);
    }

    const email = typeof body.email === 'string' ? body.email.trim().toLowerCase() : '';
    if (email.length > 254 || !emailPattern.test(email)) return json({ error: 'invalid_email' }, 400, cors);

    const trade = body.trade ?? null;
    if (trade !== null && !trades.includes(trade as Trade)) return json({ error: 'invalid_trade' }, 400, cors);

    const source = typeof body.source === 'string' && body.source.trim() !== ''
      ? body.source.trim().slice(0, 200)
      : null;

    const hasAnswers = body.answers !== undefined && body.answers !== null;
    const answers = hasAnswers ? parseAnswers(body.answers) : null;
    if (hasAnswers && answers === null) return json({ error: 'invalid_answers' }, 400, cors);

    const hasPhone = body.phone !== undefined && body.phone !== null;
    if (hasPhone && typeof body.phone !== 'string') return json({ error: 'invalid_phone' }, 400, cors);
    if (body.consent !== undefined && typeof body.consent !== 'boolean') {
      return json({ error: 'invalid_request' }, 400, cors);
    }
    const consent = body.consent === true;

    const rawPhone = hasPhone ? (body.phone as string).trim() : '';
    const phone = rawPhone === '' ? null : normalizePhone(rawPhone);
    if (rawPhone !== '' && phone === null) return json({ error: 'invalid_phone' }, 400, cors);
    if (phone !== null && !consent) return json({ error: 'consent_required' }, 400, cors);

    try {
      const key = await deps.clientKey(request);
      const allowed =
        await store.rateLimitHit(`waitlist-signup:${key}`, perClientLimit.max, perClientLimit.windowSeconds) &&
        await store.rateLimitHit('waitlist-signup:*', overallLimit.max, overallLimit.windowSeconds);
      if (!allowed) return json({ error: 'rate_limited' }, 429, { ...cors, 'retry-after': '600' });

      const result = await store.signup({ email, trade: trade as Trade | null, source, answers, phone, consent });
      const mailSent = result.mail !== null && await sendMail(deps, email, result, log);

      const response: SignupResponse = result.status === 'created'
        ? { status: 'created', promoCode: result.promoCode, mailSent }
        : { status: result.status, mailSent };
      return json(response, 200, cors);
    } catch (error) {
      log(`waitlist-signup: ${error instanceof Error ? error.message : error}`);
      return json({ error: 'server_error' }, 500, cors);
    }
  };
}

/** Sends the mail the database asked for. A vendor refusal is logged, not fatal: the sign-up stands. */
async function sendMail(
  deps: SignupDeps,
  email: string,
  result: SignupResult,
  log: (message: string) => void,
): Promise<boolean> {
  const links = mailLinks(deps.config, { confirm: result.confirmToken, unsubscribe: result.unsubscribeToken });
  const mail = result.mail === 'confirm'
    ? confirmationMail(result.promoCode, links)
    : codeMail(result.promoCode, links);
  try {
    await deps.email.send({
      from: deps.config.from,
      to: { email },
      ...mail,
      unsubscribeUrl: links.unsubscribeEndpoint,
    });
    return true;
  } catch (error) {
    if (!(error instanceof EmailGatewayError)) throw error;
    log(`waitlist-signup: mail not sent (${error.retryable ? 'retryable' : 'permanent'}): ${error.message}`);
    return false;
  }
}
