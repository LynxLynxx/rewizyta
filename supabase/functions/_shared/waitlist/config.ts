import type { EmailAddress } from '../email/email_gateway.ts';

export type Env = (name: string) => string | undefined;

/** Everything the waitlist-* functions read from their environment. */
export interface WaitlistConfig {
  /** The waitlist site, e.g. `https://example.com`. Mail links point at its pages. */
  siteUrl: string;
  /** Base URL of the edge functions, for the List-Unsubscribe header. */
  functionsUrl: string;
  /** Origins allowed to call the functions from a browser. */
  allowedOrigins: string[];
  from: EmailAddress;
  /** Where replies to the mail go (`WAITLIST_REPLY_TO`); unset, they go to [from]. */
  replyTo?: EmailAddress;
  /** Key for hashing client IPs before they reach the rate-limit table. */
  ipSalt: string;
}

/**
 * Builds the config from function secrets (see `supabase/functions/.env.example`).
 * Throws with every missing name at once, so a misconfigured project fails on
 * its first request instead of sending broken mail.
 */
export function loadWaitlistConfig(env: Env): WaitlistConfig {
  const missing: string[] = [];
  const need = (name: string): string => {
    const value = env(name)?.trim();
    if (!value) missing.push(name);
    return value ?? '';
  };

  const siteUrl = trimSlash(need('WAITLIST_SITE_URL'));
  const fromEmail = need('WAITLIST_FROM_EMAIL');
  const ipSalt = need('WAITLIST_IP_SALT');
  const functionsUrl = env('WAITLIST_FUNCTIONS_URL')?.trim() ||
    (env('SUPABASE_URL') ? `${trimSlash(env('SUPABASE_URL')!)}/functions/v1` : need('WAITLIST_FUNCTIONS_URL'));
  if (missing.length > 0) throw new Error(`waitlist config: missing ${missing.join(', ')}`);

  const replyTo = env('WAITLIST_REPLY_TO')?.trim();
  const origins = env('WAITLIST_ALLOWED_ORIGINS')?.split(',').map((o) => trimSlash(o.trim())).filter(Boolean);
  return {
    siteUrl,
    functionsUrl: trimSlash(functionsUrl),
    allowedOrigins: origins?.length ? origins : [new URL(siteUrl).origin],
    from: { email: fromEmail, name: env('WAITLIST_FROM_NAME')?.trim() || 'Rewizyta' },
    ...(replyTo ? { replyTo: { email: replyTo } } : {}),
    ipSalt,
  };
}

function trimSlash(url: string): string {
  return url.replace(/\/+$/, '');
}
