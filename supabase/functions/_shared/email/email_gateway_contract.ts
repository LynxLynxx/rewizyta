import { assert, assertEquals } from 'jsr:@std/assert@1';
import type { EmailGateway, EmailMessage } from './email_gateway.ts';

/** What an adapter put on the wire, in a vendor-neutral shape. */
export interface DeliveredEmail {
  from: { email: string; name?: string };
  to: { email: string; name?: string };
  subject: string;
  text: string;
  html: string;
  replyTo?: { email: string; name?: string };
  headers: Record<string, string>;
}

export interface GatewayHarness {
  gateway: EmailGateway;
  /** The last message the adapter handed to its vendor (or to the log). */
  lastDelivered(): DeliveredEmail;
}

const message: EmailMessage = {
  from: { email: 'lista@example.com', name: 'Rewizyta' },
  to: { email: 'jan@example.com' },
  subject: 'Potwierdź zapis',
  text: 'Tekst',
  html: '<p>Tekst</p>',
};

/**
 * The behaviour every EmailGateway must share. Each adapter's test calls this
 * with a harness; the real vendor gets the same checks by hand (a smoke test
 * with a real key) before it is switched on.
 */
export function emailGatewayContract(name: string, harness: () => GatewayHarness): void {
  Deno.test(`${name} (contract): returns the provider's message id`, async () => {
    const { gateway } = harness();
    const sent = await gateway.send(message);
    assert(sent.providerMessageId.length > 0);
  });

  Deno.test(`${name} (contract): delivers sender, recipient, subject and both bodies`, async () => {
    const h = harness();
    await h.gateway.send(message);
    const delivered = h.lastDelivered();
    assertEquals(delivered.from, message.from);
    assertEquals(delivered.to, message.to);
    assertEquals(delivered.subject, message.subject);
    assertEquals(delivered.text, message.text);
    assertEquals(delivered.html, message.html);
  });

  Deno.test(`${name} (contract): a reply-to address is delivered, and none without one`, async () => {
    const h = harness();
    await h.gateway.send(message);
    assertEquals(h.lastDelivered().replyTo, undefined);
    await h.gateway.send({ ...message, replyTo: { email: 'kontakt@example.com' } });
    assertEquals(h.lastDelivered().replyTo, { email: 'kontakt@example.com' });
  });

  Deno.test(`${name} (contract): an unsubscribe URL becomes the RFC 8058 header pair`, async () => {
    const h = harness();
    await h.gateway.send({ ...message, unsubscribeUrl: 'https://example.com/u?token=abc' });
    const headers = h.lastDelivered().headers;
    assertEquals(headers['List-Unsubscribe'], '<https://example.com/u?token=abc>');
    assertEquals(headers['List-Unsubscribe-Post'], 'List-Unsubscribe=One-Click');
  });

  Deno.test(`${name} (contract): no unsubscribe URL, no list headers`, async () => {
    const h = harness();
    await h.gateway.send(message);
    assertEquals(h.lastDelivered().headers['List-Unsubscribe'], undefined);
  });
}
