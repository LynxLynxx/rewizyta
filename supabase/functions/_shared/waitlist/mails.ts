import type { WaitlistConfig } from './config.ts';

export interface RenderedMail {
  subject: string;
  text: string;
  html: string;
}

export interface MailLinks {
  /** Page on the site with a "confirm" button; the token rides in the fragment. */
  confirmPage?: string;
  /** Page on the site with an "unsubscribe" button. */
  unsubscribePage: string;
  /** One-click endpoint for the List-Unsubscribe header (POST only). */
  unsubscribeEndpoint: string;
}

/**
 * Mail links point at pages with a button, never at an endpoint that acts on
 * GET: corporate link scanners open every URL in a message and would confirm
 * or unsubscribe on the reader's behalf. The token is in the fragment, so it
 * never reaches the CDN's logs.
 */
export function mailLinks(
  config: WaitlistConfig,
  tokens: { confirm: string | null; unsubscribe: string },
): MailLinks {
  return {
    confirmPage: tokens.confirm === null ? undefined : `${config.siteUrl}/potwierdz/#t=${tokens.confirm}`,
    unsubscribePage: `${config.siteUrl}/wypisz/#t=${tokens.unsubscribe}`,
    unsubscribeEndpoint: `${config.functionsUrl}/waitlist-unsubscribe?token=${tokens.unsubscribe}`,
  };
}

/**
 * What the code is worth. Must match the page's promise and
 * `waitlist_signups.promo_reward` (`trial_90d`, migration `*_waitlist_promo_reward.sql`).
 */
const codeReward = 'Po starcie wpiszesz go w aplikacji i dostaniesz 3 miesiące za darmo.';

/** Double opt-in: the confirmation link and the promo code. */
export function confirmationMail(promoCode: string, links: MailLinks): RenderedMail {
  const subject = 'Potwierdź zapis na listę Rewizyty';
  const intro = 'dziękujemy za zapis na listę oczekujących Rewizyty – aplikacji dla kominiarzy ' +
    'i serwisantów, która pilnuje terminów przeglądów i sama przypomina klientom SMS-em.';
  const code = `Zachowaj go. ${codeReward}`;
  const ignore = 'Jeśli ten zapis to pomyłka, zignoruj tę wiadomość. Bez potwierdzenia nie napiszemy więcej.';

  return {
    subject,
    text: [
      'Dzień dobry,',
      '',
      intro,
      '',
      'Potwierdź swój adres:',
      links.confirmPage!,
      '',
      `Twój kod: ${promoCode}`,
      code,
      '',
      ignore,
      '',
      ...footerText(links),
    ].join('\n'),
    html: layout(subject, [
      p('Dzień dobry,'),
      p(intro),
      button(links.confirmPage!, 'Potwierdzam zapis'),
      p(`Twój kod: <strong style="font-family:monospace;font-size:18px">${escape(promoCode)}</strong><br>${code}`),
      p(ignore),
    ], links),
  };
}

/** For an address that is already confirmed and signs up again. */
export function codeMail(promoCode: string, links: MailLinks): RenderedMail {
  const subject = 'Twój kod Rewizyty';
  const known = 'ten adres jest już na liście oczekujących Rewizyty.';
  const later = 'Napiszemy, gdy aplikacja będzie gotowa.';

  return {
    subject,
    text: ['Dzień dobry,', '', known, '', `Twój kod: ${promoCode}`, codeReward, '', later, '', ...footerText(links)]
      .join('\n'),
    html: layout(subject, [
      p('Dzień dobry,'),
      p(known),
      p(`Twój kod: <strong style="font-family:monospace;font-size:18px">${
        escape(promoCode)
      }</strong><br>${codeReward}`),
      p(later),
    ], links),
  };
}

function footerText(links: MailLinks): string[] {
  return ['Rewizyta', `Nie chcesz tych wiadomości? Wypisz się: ${links.unsubscribePage}`];
}

function layout(title: string, blocks: string[], links: MailLinks): string {
  return `<!doctype html>
<html lang="pl">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>${escape(title)}</title></head>
<body style="margin:0;padding:24px;background:#f4f6f8;font-family:Arial,Helvetica,sans-serif;color:#1b1f23">
<div style="max-width:560px;margin:0 auto;background:#ffffff;border-radius:8px;padding:24px">
${blocks.join('\n')}
<p style="margin:24px 0 0;font-size:13px;color:#57606a">Rewizyta<br>
Nie chcesz tych wiadomości? <a href="${escape(links.unsubscribePage)}" style="color:#57606a">Wypisz się</a>.</p>
</div>
</body>
</html>`;
}

function p(html: string): string {
  return `<p style="margin:0 0 16px;font-size:16px;line-height:1.5">${html}</p>`;
}

function button(href: string, label: string): string {
  return `<p style="margin:0 0 16px"><a href="${escape(href)}" style="display:inline-block;padding:12px 20px;` +
    `background:#1f5f8b;color:#ffffff;border-radius:6px;text-decoration:none;font-weight:bold">${
      escape(label)
    }</a></p>`;
}

function escape(value: string): string {
  return value.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');
}
