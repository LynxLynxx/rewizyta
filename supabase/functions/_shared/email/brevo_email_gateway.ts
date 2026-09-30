import {
  type EmailGateway,
  EmailGatewayError,
  type EmailMessage,
  type SentEmail,
  unsubscribeHeaders,
} from './email_gateway.ts';

export const brevoEndpoint = 'https://api.brevo.com/v3/smtp/email';

/**
 * `EMAIL_PROVIDER=brevo`: Brevo's transactional API (Paris; free plan of 300
 * mails a day). Only the plain send endpoint is used; Brevo's contact lists
 * and templates are not, because the list lives in `waitlist_signups`.
 */
export class BrevoEmailGateway implements EmailGateway {
  constructor(
    private readonly apiKey: string,
    private readonly fetchFn: typeof fetch = fetch,
  ) {}

  async send(message: EmailMessage): Promise<SentEmail> {
    let response: Response;
    try {
      response = await this.fetchFn(brevoEndpoint, {
        method: 'POST',
        headers: {
          'accept': 'application/json',
          'content-type': 'application/json',
          'api-key': this.apiKey,
        },
        body: JSON.stringify({
          sender: message.from,
          to: [message.to],
          subject: message.subject,
          textContent: message.text,
          htmlContent: message.html,
          ...(message.replyTo === undefined ? {} : { replyTo: message.replyTo }),
          headers: unsubscribeHeaders(message),
        }),
      });
    } catch (error) {
      throw new EmailGatewayError(`brevo: request failed: ${error}`, true);
    }

    const body = await response.json().catch(() => ({}));
    if (!response.ok) {
      const retryable = response.status === 429 || response.status >= 500;
      const reason = typeof body?.message === 'string' ? body.message : response.statusText;
      throw new EmailGatewayError(`brevo: ${response.status} ${reason}`, retryable);
    }
    if (typeof body?.messageId !== 'string' || body.messageId === '') {
      throw new EmailGatewayError('brevo: response without messageId', false);
    }
    return { providerMessageId: body.messageId };
  }
}
