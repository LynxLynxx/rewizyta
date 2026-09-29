import { createClient, type SupabaseClient } from 'npm:@supabase/supabase-js@2';

export type Env = (name: string) => string | undefined;

/**
 * A service-role client for functions that act without a user. Prefers the
 * new secret key (`SUPABASE_SECRET_KEYS`, a JSON map injected by the platform
 * and by `supabase functions serve`) and falls back to the legacy
 * `SUPABASE_SERVICE_ROLE_KEY` while projects still carry it.
 */
export function createAdminClient(env: Env): SupabaseClient {
  const url = env('SUPABASE_URL');
  const secretKeys = env('SUPABASE_SECRET_KEYS');
  const key = secretKeys ? JSON.parse(secretKeys).default : env('SUPABASE_SERVICE_ROLE_KEY');
  if (!url || !key) throw new Error('SUPABASE_URL and a secret key must be injected by the runtime');
  return createClient(url, key, { auth: { persistSession: false, autoRefreshToken: false } });
}
