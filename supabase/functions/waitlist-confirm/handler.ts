import { corsHeaders, isForeignOrigin, json, readJsonObject } from '../_shared/http.ts';
import type { WaitlistConfig } from '../_shared/waitlist/config.ts';
import { isToken } from '../_shared/waitlist/tokens.ts';
import type { WaitlistStore } from '../_shared/waitlist/waitlist_store.ts';

export interface ConfirmDeps {
  store: WaitlistStore;
  config: WaitlistConfig;
  log?: (message: string) => void;
}

/**
 * `POST {token}` from the site's /potwierdz/ page, after the reader presses
 * the button. Never GET: link scanners would confirm on the reader's behalf.
 * Answers `{status: 'confirmed' | 'invalid'}`; a used token is invalid.
 *
 * No rate limit, unlike waitlist-signup: nothing here sends mail, a token is
 * 256 random bits (guessing one is hopeless), and a limit kept in Postgres
 * would cost each request more than the one indexed update it guards.
 */
export function createConfirmHandler(deps: ConfirmDeps): (request: Request) => Promise<Response> {
  const log = deps.log ?? console.error;
  const { config, store } = deps;

  return async (request) => {
    const cors = corsHeaders(request, config.allowedOrigins);
    if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers: cors });
    if (request.method !== 'POST') return json({ error: 'method_not_allowed' }, 405, cors);
    if (isForeignOrigin(request, config.allowedOrigins)) return json({ error: 'forbidden' }, 403);

    const body = await readJsonObject(request);
    if (!isToken(body?.token)) return json({ error: 'invalid_request' }, 400, cors);

    try {
      const confirmed = await store.confirm(body.token);
      return json({ status: confirmed ? 'confirmed' : 'invalid' }, 200, cors);
    } catch (error) {
      log(`waitlist-confirm: ${error instanceof Error ? error.message : error}`);
      return json({ error: 'server_error' }, 500, cors);
    }
  };
}
