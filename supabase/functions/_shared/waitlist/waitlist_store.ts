import type { Answers } from './survey.ts';

/** The waitlist's database operations, one SQL function each (migration `*_waitlist.sql`). */
export interface WaitlistStore {
  signup(input: SignupInput): Promise<SignupResult>;
  /** True when the token matched a pending sign-up. */
  confirm(token: string): Promise<boolean>;
  /** True when the token belongs to a sign-up (already unsubscribed counts). */
  unsubscribe(token: string): Promise<boolean>;
  /** Counts a hit for [key]; false once more than [max] hits fall in the window. */
  rateLimitHit(key: string, max: number, windowSeconds: number): Promise<boolean>;
}

export const trades = ['chimney', 'gas', 'boiler', 'other'] as const;
export type Trade = typeof trades[number];

export interface SignupInput {
  email: string;
  trade: Trade | null;
  source: string | null;
  /** Validated by `parseAnswers`; null when the page sent none. */
  answers: Answers | null;
  /** E.164, only together with [consent]. */
  phone: string | null;
  /** The visitor ticked "contact me about Rewizyta". */
  consent: boolean;
}

/** Mirrors the jsonb returned by `public.waitlist_signup`. */
export interface SignupResult {
  status: 'created' | 'pending' | 'confirmed' | 'resubscribed';
  /** Which mail to send now; null when one went out in the last 15 minutes. */
  mail: 'confirm' | 'code' | null;
  promoCode: string;
  /** Set when [mail] is `confirm`. */
  confirmToken: string | null;
  unsubscribeToken: string;
}
