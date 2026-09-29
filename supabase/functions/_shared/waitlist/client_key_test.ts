import { assertEquals, assertMatch, assertNotEquals } from 'jsr:@std/assert@1';
import { clientIp, clientKey } from './client_key.ts';

const request = (headers: Record<string, string>) => new Request('https://example.com', { headers });

Deno.test('clientIp prefers the CDN header, then x-real-ip, then the first forwarded hop', () => {
  assertEquals(
    clientIp(
      request({ 'cf-connecting-ip': '198.51.100.1', 'x-real-ip': '198.51.100.2', 'x-forwarded-for': '198.51.100.3' }),
    ),
    '198.51.100.1',
  );
  assertEquals(clientIp(request({ 'x-real-ip': '198.51.100.2', 'x-forwarded-for': '198.51.100.3' })), '198.51.100.2');
  assertEquals(clientIp(request({ 'x-forwarded-for': '198.51.100.3, 10.0.0.1' })), '198.51.100.3');
  assertEquals(clientIp(request({})), null);
});

Deno.test('clientKey is a stable keyed hash, never the address', async () => {
  const caller = request({ 'x-forwarded-for': '198.51.100.3' });

  const key = await clientKey(caller, 'salt');

  assertMatch(key, /^[0-9a-f]{32}$/);
  assertEquals(await clientKey(caller, 'salt'), key);
  assertNotEquals(await clientKey(caller, 'other salt'), key);
  assertNotEquals(await clientKey(request({ 'x-forwarded-for': '198.51.100.4' }), 'salt'), key);
});
