import { assertEquals } from 'jsr:@std/assert@1';
import { confirmToken, FakeWaitlistStore, post, testConfig } from '../_shared/waitlist/testing.ts';
import { createConfirmHandler } from './handler.ts';

const url = 'https://api.example.com/functions/v1/waitlist-confirm';

function setUp() {
  const store = new FakeWaitlistStore();
  return { store, handler: createConfirmHandler({ store, config: testConfig, log: () => {} }) };
}

Deno.test('a pending token confirms', async () => {
  const { store, handler } = setUp();

  const response = await handler(post(url, { token: confirmToken }));

  assertEquals(await response.json(), { status: 'confirmed' });
  assertEquals(store.confirmed, [confirmToken]);
  assertEquals(response.headers.get('access-control-allow-origin'), testConfig.siteUrl);
});

Deno.test('an unknown or used token is invalid, not an error', async () => {
  const { handler } = setUp();

  const response = await handler(post(url, { token: 'z'.repeat(43) }));

  assertEquals(response.status, 200);
  assertEquals(await response.json(), { status: 'invalid' });
});

Deno.test('a malformed token never reaches the database', async () => {
  const { store, handler } = setUp();

  for (const token of [undefined, 'short', `${confirmToken}'; drop table`, 42]) {
    assertEquals((await handler(post(url, { token }))).status, 400);
  }
  assertEquals(store.confirmed.length, 0);
});

Deno.test('GET does not confirm', async () => {
  const { store, handler } = setUp();

  const response = await handler(new Request(`${url}?token=${confirmToken}`));

  assertEquals(response.status, 405);
  assertEquals(store.confirmed.length, 0);
});

Deno.test('a page on another origin is refused', async () => {
  const { handler } = setUp();
  assertEquals((await handler(post(url, { token: confirmToken }, 'https://evil.example.org'))).status, 403);
});

Deno.test('a database failure is a 500', async () => {
  const { store, handler } = setUp();
  store.failWith = new Error('down');
  assertEquals((await handler(post(url, { token: confirmToken }))).status, 500);
});
