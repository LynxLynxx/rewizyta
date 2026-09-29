import { assertEquals, assertRejects } from 'jsr:@std/assert@1';
import { BrevoEmailGateway, brevoEndpoint } from './brevo_email_gateway.ts';
import { EmailGatewayError, type EmailMessage } from './email_gateway.ts';
import { type DeliveredEmail, emailGatewayContract } from './email_gateway_contract.ts';

/** Records requests and answers like Brevo does. */
function fakeBrevo(reply: () => Response = () => Response.json({ messageId: '<1@smtp-relay>' }, { status: 201 })) {
  const requests: Request[] = [];
  const fetchFn: typeof fetch = (input, init) => {
    requests.push(new Request(input, init));
    return Promise.resolve(reply());
  };
  return { requests, fetchFn };
}

emailGatewayContract('BrevoEmailGateway', () => {
  const brevo = fakeBrevo();
  const bodies: DeliveredEmail[] = [];
  const gateway = new BrevoEmailGateway('key', (input, init) => {
    const payload = JSON.parse(String(init?.body));
    bodies.push({
      from: payload.sender,
      to: payload.to[0],
      subject: payload.subject,
      text: payload.textContent,
      html: payload.htmlContent,
      headers: payload.headers,
    });
    return brevo.fetchFn(input, init);
  });
  return { gateway, lastDelivered: () => bodies.at(-1)! };
});

const message: EmailMessage = {
  from: { email: 'lista@example.com' },
  to: { email: 'jan@example.com' },
  subject: 'S',
  text: 'T',
  html: '<p>T</p>',
};

Deno.test('BrevoEmailGateway posts JSON to the transactional endpoint with the api-key header', async () => {
  const brevo = fakeBrevo();
  await new BrevoEmailGateway('secret-key', brevo.fetchFn).send(message);

  const request = brevo.requests[0];
  assertEquals(request.url, brevoEndpoint);
  assertEquals(request.method, 'POST');
  assertEquals(request.headers.get('api-key'), 'secret-key');
  assertEquals(request.headers.get('content-type'), 'application/json');
});

Deno.test('BrevoEmailGateway: a 400 is a permanent failure', async () => {
  const brevo = fakeBrevo(() => Response.json({ code: 'invalid_parameter', message: 'bad email' }, { status: 400 }));
  const error = await assertRejects(
    () => new BrevoEmailGateway('k', brevo.fetchFn).send(message),
    EmailGatewayError,
    'bad email',
  );
  assertEquals(error.retryable, false);
});

Deno.test('BrevoEmailGateway: 429 and 5xx can be retried', async () => {
  for (const status of [429, 503]) {
    const brevo = fakeBrevo(() => new Response('', { status }));
    const error = await assertRejects(
      () => new BrevoEmailGateway('k', brevo.fetchFn).send(message),
      EmailGatewayError,
    );
    assertEquals(error.retryable, true, `status ${status}`);
  }
});

Deno.test('BrevoEmailGateway: a network error can be retried', async () => {
  const error = await assertRejects(
    () => new BrevoEmailGateway('k', () => Promise.reject(new TypeError('offline'))).send(message),
    EmailGatewayError,
  );
  assertEquals(error.retryable, true);
});
