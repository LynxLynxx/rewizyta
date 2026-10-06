/**
 * What every e-mail vendor can do: send one message. Vendor extras (templates,
 * contact lists, campaigns) are deliberately left out so switching vendors is
 * one class and one secret (docs/TRD.md, "Messaging: start free, swap
 * by config"). Adapters are chosen by `EMAIL_PROVIDER` in `create_email_gateway.ts`.
 */
export interface EmailGateway {
  send(message: EmailMessage): Promise<SentEmail>;
}

export interface EmailAddress {
  email: string;
  name?: string;
}

export interface EmailMessage {
  from: EmailAddress;
  to: EmailAddress;
  subject: string;
  text: string;
  html: string;
  /** Where replies go, for a [from] address with no mailbox behind it. */
  replyTo?: EmailAddress;
  /**
   * HTTPS endpoint that unsubscribes the recipient on POST. Adapters send it as
   * `List-Unsubscribe: <url>` plus `List-Unsubscribe-Post: List-Unsubscribe=One-Click`
   * (RFC 2369, RFC 8058), which Gmail and Yahoo require for bulk senders.
   */
  unsubscribeUrl?: string;
}

export interface SentEmail {
  /** The vendor's id for the message, for matching delivery reports later. */
  providerMessageId: string;
}

/** The vendor refused or could not be reached. */
export class EmailGatewayError extends Error {
  constructor(
    message: string,
    /** True when trying again later may succeed (network, 429, 5xx). */
    readonly retryable: boolean,
  ) {
    super(message);
    this.name = 'EmailGatewayError';
  }
}

/** The RFC 8058 header pair for [EmailMessage.unsubscribeUrl]. */
export function unsubscribeHeaders(message: EmailMessage): Record<string, string> {
  if (message.unsubscribeUrl === undefined) return {};
  return {
    'List-Unsubscribe': `<${message.unsubscribeUrl}>`,
    'List-Unsubscribe-Post': 'List-Unsubscribe=One-Click',
  };
}
