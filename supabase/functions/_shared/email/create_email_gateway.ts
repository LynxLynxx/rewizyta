import { BrevoEmailGateway } from './brevo_email_gateway.ts';
import { ConsoleEmailGateway } from './console_email_gateway.ts';
import type { EmailGateway } from './email_gateway.ts';

export type Env = (name: string) => string | undefined;

/**
 * The one place that knows which vendor is active. `EMAIL_PROVIDER` is a
 * function secret: `console` locally, `brevo` on hosted projects. A new vendor
 * is one class plus one case here.
 */
export function createEmailGateway(env: Env): EmailGateway {
  const provider = env('EMAIL_PROVIDER');
  switch (provider) {
    case 'console':
      return new ConsoleEmailGateway();
    case 'brevo':
      return new BrevoEmailGateway(required(env, 'BREVO_API_KEY'));
    default:
      throw new Error(`EMAIL_PROVIDER must be one of console, brevo (got ${provider ?? 'nothing'})`);
  }
}

function required(env: Env, name: string): string {
  const value = env(name);
  if (!value) throw new Error(`${name} is not set`);
  return value;
}
