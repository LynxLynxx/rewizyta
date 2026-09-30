import { assertEquals, assertStringIncludes } from 'jsr:@std/assert@1';
import { ConsoleEmailGateway } from '../_shared/email/console_email_gateway.ts';
import { EmailGatewayError } from '../_shared/email/email_gateway.ts';
import { confirmToken, FakeWaitlistStore, post, testConfig, unsubscribeToken } from '../_shared/waitlist/testing.ts';
import { createSignupHandler } from './handler.ts';

const url = 'https://api.example.com/functions/v1/waitlist-signup';

function setUp() {
  const store = new FakeWaitlistStore();
  const email = new ConsoleEmailGateway(() => {});
  const logs: string[] = [];
  const handler = createSignupHandler({
    store,
    email,
    config: testConfig,
    clientKey: () => Promise.resolve('client'),
    log: (message) => logs.push(message),
  });
  return { store, email, logs, handler };
}

Deno.test('a new address is stored, mailed and gets its promo code back', async () => {
  const { store, email, handler } = setUp();

  const response = await handler(post(url, { email: ' JAN@example.com ', trade: 'chimney', source: ' fb ' }));

  assertEquals(response.status, 200);
  assertEquals(await response.json(), { status: 'created', promoCode: 'REWI-7K3M-9QZT', mailSent: true });
  assertEquals(response.headers.get('access-control-allow-origin'), testConfig.siteUrl);
  assertEquals(store.signups, [
    { email: 'jan@example.com', trade: 'chimney', source: 'fb', answers: null, phone: null, consent: false },
  ]);

  const mail = email.sent[0];
  assertEquals(mail.to, { email: 'jan@example.com' });
  assertEquals(mail.from, testConfig.from);
  assertEquals(mail.replyTo, testConfig.replyTo);
  assertEquals(mail.subject, 'Potwierdź zapis na listę Rewizyty');
  assertStringIncludes(mail.text, `https://waitlist.example.com/potwierdz/#t=${confirmToken}`);
  assertStringIncludes(mail.text, 'REWI-7K3M-9QZT');
  assertEquals(
    mail.headers['List-Unsubscribe'],
    `<https://api.example.com/functions/v1/waitlist-unsubscribe?token=${unsubscribeToken}>`,
  );
});

Deno.test('the survey, a phone number and the consent are passed on', async () => {
  const { store, handler } = setUp();

  const response = await handler(post(url, {
    email: 'jan@example.com',
    answers: { trade: ['chimney', 'other'], trade_other: ' szamba ', clients: '50_200', would_pay: 'maybe' },
    phone: '601 234 567',
    consent: true,
  }));

  assertEquals(response.status, 200);
  assertEquals(store.signups[0].answers, {
    trade: ['chimney', 'other'],
    trade_other: 'szamba',
    clients: '50_200',
    would_pay: 'maybe',
  });
  assertEquals(store.signups[0].phone, '+48601234567');
  assertEquals(store.signups[0].consent, true);
});

Deno.test('a known address never gets the promo code in the response', async () => {
  const { store, email, handler } = setUp();
  store.signupResult = { ...store.signupResult, status: 'confirmed', mail: 'code', confirmToken: null };

  const response = await handler(post(url, { email: 'jan@example.com' }));

  assertEquals(await response.json(), { status: 'confirmed', mailSent: true });
  assertEquals(email.sent[0].subject, 'Twój kod Rewizyty');
  assertStringIncludes(email.sent[0].text, 'REWI-7K3M-9QZT');
});

Deno.test('a throttled repeat sends nothing', async () => {
  const { store, email, handler } = setUp();
  store.signupResult = { ...store.signupResult, status: 'pending', mail: null, confirmToken: null };

  const response = await handler(post(url, { email: 'jan@example.com' }));

  assertEquals(await response.json(), { status: 'pending', mailSent: false });
  assertEquals(email.sent.length, 0);
});

Deno.test('a vendor refusal keeps the sign-up and reports mailSent false', async () => {
  const { store, logs } = setUp();
  const handler = createSignupHandler({
    store,
    email: { send: () => Promise.reject(new EmailGatewayError('brevo: 503', true)) },
    config: testConfig,
    clientKey: () => Promise.resolve('client'),
    log: (message) => logs.push(message),
  });

  const response = await handler(post(url, { email: 'jan@example.com' }));

  assertEquals(await response.json(), { status: 'created', promoCode: 'REWI-7K3M-9QZT', mailSent: false });
  assertStringIncludes(logs[0], 'retryable');
});

Deno.test('the decoy field gets a fake success and touches nothing', async () => {
  const { store, email, handler } = setUp();

  const response = await handler(post(url, { email: 'bot@example.com', website: 'http://spam' }));

  assertEquals(response.status, 200);
  assertEquals(store.signups.length + store.hits.length + email.sent.length, 0);
});

Deno.test('invalid input is refused before any database call', async () => {
  const { store, handler } = setUp();

  for (
    const [body, error] of [
      [{ email: 'not-an-email' }, 'invalid_email'],
      [{ email: `${'a'.repeat(250)}@example.com` }, 'invalid_email'],
      [{ email: 'jan@example.com', trade: 'plumber' }, 'invalid_trade'],
      [{ email: 'jan@example.com', answers: { clients: 'thousands' } }, 'invalid_answers'],
      [{ email: 'jan@example.com', answers: ['chimney'] }, 'invalid_answers'],
      [{ email: 'jan@example.com', phone: '12', consent: true }, 'invalid_phone'],
      [{ email: 'jan@example.com', phone: 601234567, consent: true }, 'invalid_phone'],
      [{ email: 'jan@example.com', phone: '601 234 567' }, 'consent_required'],
      [{ email: 'jan@example.com', consent: 'yes' }, 'invalid_request'],
      [['jan@example.com'], 'invalid_request'],
    ] as const
  ) {
    const response = await handler(post(url, body));
    assertEquals(response.status, 400);
    assertEquals((await response.json()).error, error);
  }
  assertEquals(store.hits.length, 0);
});

Deno.test('the source is cut to 200 characters', async () => {
  const { store, handler } = setUp();

  await handler(post(url, { email: 'jan@example.com', source: 'x'.repeat(500) }));

  assertEquals(store.signups[0].source?.length, 200);
});

Deno.test('a caller over the limit gets 429 and the overall counter is not charged', async () => {
  const { store, handler } = setUp();
  store.limitedKeys = ['waitlist-signup:client'];

  const response = await handler(post(url, { email: 'jan@example.com' }));

  assertEquals(response.status, 429);
  assertEquals(store.hits, ['waitlist-signup:client']);
  assertEquals(store.signups.length, 0);
});

Deno.test('the overall cap applies to everyone', async () => {
  const { store, handler } = setUp();
  store.limitedKeys = ['waitlist-signup:*'];

  const response = await handler(post(url, { email: 'jan@example.com' }));

  assertEquals(response.status, 429);
});

Deno.test('a page on another origin is refused', async () => {
  const { store, handler } = setUp();

  const response = await handler(post(url, { email: 'jan@example.com' }, 'https://evil.example.org'));

  assertEquals(response.status, 403);
  assertEquals(response.headers.get('access-control-allow-origin'), null);
  assertEquals(store.hits.length, 0);
});

Deno.test('the CORS preflight is answered for the site only', async () => {
  const { handler } = setUp();
  const preflight = (origin: string) => handler(new Request(url, { method: 'OPTIONS', headers: { origin } }));

  const ours = await preflight(testConfig.siteUrl);
  assertEquals(ours.status, 204);
  assertEquals(ours.headers.get('access-control-allow-methods'), 'POST, OPTIONS');

  const theirs = await preflight('https://evil.example.org');
  assertEquals(theirs.headers.get('access-control-allow-origin'), null);
});

Deno.test('GET is not allowed', async () => {
  const { handler } = setUp();
  assertEquals((await handler(new Request(url))).status, 405);
});

Deno.test('a database failure is a logged 500', async () => {
  const { store, logs, handler } = setUp();
  store.failWith = new Error('connection refused');

  const response = await handler(post(url, { email: 'jan@example.com' }));

  assertEquals(response.status, 500);
  assertEquals(await response.json(), { error: 'server_error' });
  assertStringIncludes(logs[0], 'connection refused');
});
