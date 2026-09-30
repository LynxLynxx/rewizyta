import type { SupabaseClient } from 'npm:@supabase/supabase-js@2';
import type { SignupInput, SignupResult, WaitlistStore } from './waitlist_store.ts';

/** [WaitlistStore] over the service-role-only SQL functions, through PostgREST RPC. */
export class SupabaseWaitlistStore implements WaitlistStore {
  constructor(private readonly client: SupabaseClient) {}

  async signup(input: SignupInput): Promise<SignupResult> {
    const row = await this.call<Record<string, string | null>>('waitlist_signup', {
      p_email: input.email,
      p_trade: input.trade,
      p_source: input.source,
      p_answers: input.answers,
      p_phone: input.phone,
      p_consent: input.consent,
    });
    return {
      status: row.status as SignupResult['status'],
      mail: row.mail as SignupResult['mail'],
      promoCode: row.promo_code!,
      confirmToken: row.confirm_token,
      unsubscribeToken: row.unsubscribe_token!,
    };
  }

  confirm(token: string): Promise<boolean> {
    return this.call<boolean>('waitlist_confirm', { p_token: token });
  }

  unsubscribe(token: string): Promise<boolean> {
    return this.call<boolean>('waitlist_unsubscribe', { p_token: token });
  }

  rateLimitHit(key: string, max: number, windowSeconds: number): Promise<boolean> {
    return this.call<boolean>('rate_limit_hit', {
      p_key: key,
      p_max: max,
      p_window: `${windowSeconds} seconds`,
    });
  }

  private async call<T>(fn: string, args: Record<string, unknown>): Promise<T> {
    const { data, error } = await this.client.rpc(fn, args);
    if (error) throw new Error(`${fn}: ${error.message}`);
    return data as T;
  }
}
