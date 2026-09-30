import { assertEquals, assertThrows } from 'jsr:@std/assert@1';
import { loadWaitlistConfig } from './config.ts';

const env = (values: Record<string, string>) => (name: string) => values[name];

const minimal = {
  WAITLIST_SITE_URL: 'https://waitlist.example.com/',
  WAITLIST_FROM_EMAIL: 'lista@example.com',
  WAITLIST_IP_SALT: 'salt',
  SUPABASE_URL: 'https://api.example.com/',
};

Deno.test('defaults: functions under SUPABASE_URL, the site as the only origin, sender name Rewizyta', () => {
  assertEquals(loadWaitlistConfig(env(minimal)), {
    siteUrl: 'https://waitlist.example.com',
    functionsUrl: 'https://api.example.com/functions/v1',
    allowedOrigins: ['https://waitlist.example.com'],
    from: { email: 'lista@example.com', name: 'Rewizyta' },
    ipSalt: 'salt',
  });
});

Deno.test('overrides: explicit functions URL, several origins, sender name, reply-to', () => {
  const config = loadWaitlistConfig(env({
    ...minimal,
    WAITLIST_FUNCTIONS_URL: 'http://127.0.0.1:54321/functions/v1/',
    WAITLIST_ALLOWED_ORIGINS: 'http://localhost:8080, https://waitlist.example.com/',
    WAITLIST_FROM_NAME: 'Rewizyta – lista',
    WAITLIST_REPLY_TO: ' kontakt@example.com ',
  }));

  assertEquals(config.functionsUrl, 'http://127.0.0.1:54321/functions/v1');
  assertEquals(config.allowedOrigins, ['http://localhost:8080', 'https://waitlist.example.com']);
  assertEquals(config.from.name, 'Rewizyta – lista');
  assertEquals(config.replyTo, { email: 'kontakt@example.com' });
});

Deno.test('every missing variable is named at once', () => {
  assertThrows(
    () => loadWaitlistConfig(env({})),
    Error,
    'missing WAITLIST_SITE_URL, WAITLIST_FROM_EMAIL, WAITLIST_IP_SALT, WAITLIST_FUNCTIONS_URL',
  );
});
