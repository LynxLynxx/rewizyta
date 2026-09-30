// waitlist-unsubscribe: one-click List-Unsubscribe and the site's /wypisz/ page (no JWT; see config.toml).
import { createAdminClient } from '../_shared/supabase_admin.ts';
import { loadWaitlistConfig } from '../_shared/waitlist/config.ts';
import { SupabaseWaitlistStore } from '../_shared/waitlist/supabase_waitlist_store.ts';
import { createUnsubscribeHandler } from './handler.ts';

const env = (name: string) => Deno.env.get(name);

Deno.serve(createUnsubscribeHandler({
  store: new SupabaseWaitlistStore(createAdminClient(env)),
  config: loadWaitlistConfig(env),
}));
