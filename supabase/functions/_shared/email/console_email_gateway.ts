import { type EmailGateway, type EmailMessage, type SentEmail, unsubscribeHeaders } from './email_gateway.ts';

/** A message as the console gateway "delivered" it: the fields plus the headers. */
export interface LoggedEmail extends EmailMessage {
  headers: Record<string, string>;
  providerMessageId: string;
}

/**
 * `EMAIL_PROVIDER=console`: prints the message instead of sending it, so the
 * whole flow runs under `supabase functions serve` with no vendor account.
 * The log contains the recipient and the links, so it is for local
 * development only.
 */
export class ConsoleEmailGateway implements EmailGateway {
  /** Every message sent through this instance, oldest first. */
  readonly sent: LoggedEmail[] = [];

  constructor(private readonly log: (line: string) => void = console.log) {}

  send(message: EmailMessage): Promise<SentEmail> {
    const providerMessageId = `console-${crypto.randomUUID()}`;
    const headers = unsubscribeHeaders(message);
    this.sent.push({ ...message, headers, providerMessageId });
    this.log(
      [
        `[email:console] ${providerMessageId}`,
        `From: ${format(message.from)}`,
        `To: ${format(message.to)}`,
        ...(message.replyTo === undefined ? [] : [`Reply-To: ${format(message.replyTo)}`]),
        `Subject: ${message.subject}`,
        ...Object.entries(headers).map(([name, value]) => `${name}: ${value}`),
        '',
        message.text,
      ].join('\n'),
    );
    return Promise.resolve({ providerMessageId });
  }
}

function format(address: { email: string; name?: string }): string {
  return address.name ? `${address.name} <${address.email}>` : address.email;
}
