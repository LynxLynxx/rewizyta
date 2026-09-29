// waitlist-confirm: the double opt-in button on the site's /potwierdz/ page (no JWT; see config.toml).
import { createAdminClient } from '../_shared/supabase_admin.ts';
import { loadWaitlistConfig } from '../_shared/waitlist/config.ts';
import { SupabaseWaitlistStore } from '../_shared/waitlist/supabase_waitlist_store.ts';
import { createConfirmHandler } from './handler.ts';

const env = (name: string) => Deno.env.get(name);

Deno.serve(createConfirmHandler({
  store: new SupabaseWaitlistStore(createAdminClient(env)),
  config: loadWaitlistConfig(env),
}));
