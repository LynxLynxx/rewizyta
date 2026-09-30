// waitlist-signup: the waitlist page's form posts here (no JWT; see config.toml).
import { createEmailGateway } from '../_shared/email/create_email_gateway.ts';
import { createAdminClient } from '../_shared/supabase_admin.ts';
import { clientKey } from '../_shared/waitlist/client_key.ts';
import { loadWaitlistConfig } from '../_shared/waitlist/config.ts';
import { SupabaseWaitlistStore } from '../_shared/waitlist/supabase_waitlist_store.ts';
import { createSignupHandler } from './handler.ts';

const env = (name: string) => Deno.env.get(name);
const config = loadWaitlistConfig(env);

Deno.serve(createSignupHandler({
  store: new SupabaseWaitlistStore(createAdminClient(env)),
  email: createEmailGateway(env),
  config,
  clientKey: (request) => clientKey(request, config.ipSalt),
}));
