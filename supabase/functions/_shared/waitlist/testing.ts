// Test doubles shared by the waitlist handler tests. Not imported by any function.
import type { WaitlistConfig } from './config.ts';
import type { SignupInput, SignupResult, WaitlistStore } from './waitlist_store.ts';

export const confirmToken = 'c'.repeat(43);
export const unsubscribeToken = 'u'.repeat(43);

export const testConfig: WaitlistConfig = {
  siteUrl: 'https://waitlist.example.com',
  functionsUrl: 'https://api.example.com/functions/v1',
  allowedOrigins: ['https://waitlist.example.com'],
  from: { email: 'lista@example.com', name: 'Rewizyta' },
  replyTo: { email: 'kontakt@example.com' },
  ipSalt: 'salt',
};

/** An in-memory [WaitlistStore] that records calls and answers what it is told. */
export class FakeWaitlistStore implements WaitlistStore {
  readonly signups: SignupInput[] = [];
  readonly hits: string[] = [];
  readonly confirmed: string[] = [];
  readonly unsubscribed: string[] = [];

  signupResult: SignupResult = {
    status: 'created',
    mail: 'confirm',
    promoCode: 'REWI-7K3M-9QZT',
    confirmToken,
    unsubscribeToken,
  };
  /** Keys refused by [rateLimitHit]. */
  limitedKeys: string[] = [];
  /** Tokens [confirm] and [unsubscribe] know. */
  knownTokens = [confirmToken, unsubscribeToken];
  failWith: Error | null = null;

  signup(input: SignupInput): Promise<SignupResult> {
    this.signups.push(input);
    return this.answer(this.signupResult);
  }

  confirm(token: string): Promise<boolean> {
    this.confirmed.push(token);
    return this.answer(this.knownTokens.includes(token));
  }

  unsubscribe(token: string): Promise<boolean> {
    this.unsubscribed.push(token);
    return this.answer(this.knownTokens.includes(token));
  }

  rateLimitHit(key: string): Promise<boolean> {
    this.hits.push(key);
    return this.answer(!this.limitedKeys.some((limited) => key.startsWith(limited)));
  }

  private answer<T>(value: T): Promise<T> {
    return this.failWith === null ? Promise.resolve(value) : Promise.reject(this.failWith);
  }
}

/** A JSON POST as the waitlist page sends it. */
export function post(url: string, body: unknown, origin: string | null = testConfig.siteUrl): Request {
  const headers: Record<string, string> = { 'content-type': 'application/json' };
  if (origin !== null) headers.origin = origin;
  return new Request(url, { method: 'POST', headers, body: JSON.stringify(body) });
}
