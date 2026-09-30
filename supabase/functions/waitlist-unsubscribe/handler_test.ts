import { assertEquals } from 'jsr:@std/assert@1';
import { FakeWaitlistStore, post, testConfig, unsubscribeToken } from '../_shared/waitlist/testing.ts';
import { createUnsubscribeHandler } from './handler.ts';

const url = 'https://api.example.com/functions/v1/waitlist-unsubscribe';

function setUp() {
  const store = new FakeWaitlistStore();
  return { store, handler: createUnsubscribeHandler({ store, config: testConfig, log: () => {} }) };
}

Deno.test('RFC 8058 one-click: a POST to the header URL unsubscribes', async () => {
  const { store, handler } = setUp();

  const response = await handler(
    new Request(`${url}?token=${unsubscribeToken}`, {
      method: 'POST',
      headers: { 'content-type': 'application/x-www-form-urlencoded' },
      body: 'List-Unsubscribe=One-Click',
    }),
  );

  assertEquals(response.status, 200);
  assertEquals(await response.json(), { status: 'unsubscribed' });
  assertEquals(store.unsubscribed, [unsubscribeToken]);
});

Deno.test('the /wypisz/ page posts the token as JSON', async () => {
  const { store, handler } = setUp();

  const response = await handler(post(url, { token: unsubscribeToken }));

  assertEquals(await response.json(), { status: 'unsubscribed' });
  assertEquals(store.unsubscribed, [unsubscribeToken]);
  assertEquals(response.headers.get('access-control-allow-origin'), testConfig.siteUrl);
});

Deno.test('GET redirects to the page with the button and unsubscribes nobody', async () => {
  const { store, handler } = setUp();

  const response = await handler(new Request(`${url}?token=${unsubscribeToken}`));

  assertEquals(response.status, 303);
  assertEquals(response.headers.get('location'), `https://waitlist.example.com/wypisz/#t=${unsubscribeToken}`);
  assertEquals(store.unsubscribed.length, 0);
});

Deno.test('GET with a malformed token is refused, so nothing odd lands in Location', async () => {
  const { handler } = setUp();

  const response = await handler(new Request(`${url}?token=${encodeURIComponent('https://evil.example.org')}`));

  assertEquals(response.status, 400);
  assertEquals(response.headers.get('location'), null);
});

Deno.test('an unknown token is invalid', async () => {
  const { handler } = setUp();
  assertEquals(await (await handler(post(url, { token: 'z'.repeat(43) }))).json(), { status: 'invalid' });
});

Deno.test('a POST without a token is refused', async () => {
  const { store, handler } = setUp();
  assertEquals((await handler(post(url, {}))).status, 400);
  assertEquals(store.unsubscribed.length, 0);
});

Deno.test('a page on another origin is refused', async () => {
  const { handler } = setUp();
  assertEquals((await handler(post(url, { token: unsubscribeToken }, 'https://evil.example.org'))).status, 403);
});
