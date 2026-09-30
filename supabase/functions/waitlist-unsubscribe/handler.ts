import { corsHeaders, isForeignOrigin, json, readJsonObject } from '../_shared/http.ts';
import type { WaitlistConfig } from '../_shared/waitlist/config.ts';
import { isToken } from '../_shared/waitlist/tokens.ts';
import type { WaitlistStore } from '../_shared/waitlist/waitlist_store.ts';

export interface UnsubscribeDeps {
  store: WaitlistStore;
  config: WaitlistConfig;
  log?: (message: string) => void;
}

/**
 * Three callers:
 * - `POST ?token=…` from a mail provider: RFC 8058 one-click unsubscribe, the
 *   URL in our `List-Unsubscribe` header. No Origin, body is ignored.
 * - `POST {token}` from the site's /wypisz/ page.
 * - `GET ?token=…` from a mail client that opens the header URL in a browser:
 *   redirected to the /wypisz/ page, because GET must not act (link scanners)
 *   and hosted functions cannot serve HTML on GET.
 * Answers `{status: 'unsubscribed' | 'invalid'}`.
 *
 * No rate limit, on purpose: one-click unsubscribes arrive from a mail
 * provider's few addresses, and throttling them would ignore opt-outs we must
 * honour. The token is 256 random bits, so there is nothing to guess.
 */
export function createUnsubscribeHandler(deps: UnsubscribeDeps): (request: Request) => Promise<Response> {
  const log = deps.log ?? console.error;
  const { config, store } = deps;

  return async (request) => {
    const cors = corsHeaders(request, config.allowedOrigins);
    const queryToken = new URL(request.url).searchParams.get('token');

    if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers: cors });
    if (request.method === 'GET') {
      if (!isToken(queryToken)) return json({ error: 'invalid_request' }, 400);
      return new Response(null, { status: 303, headers: { location: `${config.siteUrl}/wypisz/#t=${queryToken}` } });
    }
    if (request.method !== 'POST') return json({ error: 'method_not_allowed' }, 405, cors);
    if (isForeignOrigin(request, config.allowedOrigins)) return json({ error: 'forbidden' }, 403);

    const token = queryToken ?? (await readJsonObject(request))?.token;
    if (!isToken(token)) return json({ error: 'invalid_request' }, 400, cors);

    try {
      const unsubscribed = await store.unsubscribe(token);
      return json({ status: unsubscribed ? 'unsubscribed' : 'invalid' }, 200, cors);
    } catch (error) {
      log(`waitlist-unsubscribe: ${error instanceof Error ? error.message : error}`);
      return json({ error: 'server_error' }, 500, cors);
    }
  };
}
