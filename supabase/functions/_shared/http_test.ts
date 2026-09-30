import { assert, assertEquals } from 'jsr:@std/assert@1';
import { readJsonObject } from './http.ts';

const request = (body: string, contentType = 'application/json') =>
  new Request('https://example.com', { method: 'POST', headers: { 'content-type': contentType }, body });

Deno.test('readJsonObject returns a JSON object', async () => {
  assertEquals(await readJsonObject(request('{"email":"a@example.com"}')), { email: 'a@example.com' });
  assertEquals(await readJsonObject(request('{}', 'application/json; charset=utf-8')), {});
});

Deno.test('readJsonObject refuses anything else', async () => {
  for (
    const input of [
      request('[1]'),
      request('"text"'),
      request('null'),
      request('{not json'),
      request('{}', 'text/plain'),
      request(JSON.stringify({ padding: 'x'.repeat(5000) })),
    ]
  ) {
    assertEquals(await readJsonObject(input), null);
  }
});

Deno.test('readJsonObject stops reading a body once it passes the limit', async () => {
  let chunks = 0;
  const endless = new ReadableStream<Uint8Array>({
    pull(controller) {
      chunks++;
      controller.enqueue(new TextEncoder().encode('x'.repeat(1024)));
    },
  });
  const body = new Request('https://example.com', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: endless,
  });

  assertEquals(await readJsonObject(body), null);
  assert(chunks < 10, `read ${chunks} chunks of an endless body`);
});

Deno.test('readJsonObject refuses a declared length over the limit without reading', async () => {
  const body = request('{}');
  body.headers.set('content-length', '999999');
  assertEquals(await readJsonObject(body), null);
});
