import { assertInstanceOf, assertThrows } from 'jsr:@std/assert@1';
import { BrevoEmailGateway } from './brevo_email_gateway.ts';
import { ConsoleEmailGateway } from './console_email_gateway.ts';
import { createEmailGateway } from './create_email_gateway.ts';

const env = (values: Record<string, string>) => (name: string) => values[name];

Deno.test('createEmailGateway picks the adapter named by EMAIL_PROVIDER', () => {
  assertInstanceOf(createEmailGateway(env({ EMAIL_PROVIDER: 'console' })), ConsoleEmailGateway);
  assertInstanceOf(
    createEmailGateway(env({ EMAIL_PROVIDER: 'brevo', BREVO_API_KEY: 'k' })),
    BrevoEmailGateway,
  );
});

Deno.test('createEmailGateway refuses to guess', () => {
  assertThrows(() => createEmailGateway(env({})), Error, 'EMAIL_PROVIDER');
  assertThrows(() => createEmailGateway(env({ EMAIL_PROVIDER: 'sendgrid' })), Error, 'sendgrid');
  assertThrows(() => createEmailGateway(env({ EMAIL_PROVIDER: 'brevo' })), Error, 'BREVO_API_KEY');
});
