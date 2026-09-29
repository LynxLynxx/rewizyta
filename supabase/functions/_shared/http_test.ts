import { assertEquals } from 'jsr:@std/assert@1';
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
