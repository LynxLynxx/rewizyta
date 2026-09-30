import { assert, assertEquals, assertStringIncludes } from 'jsr:@std/assert@1';
import { codeMail, confirmationMail, mailLinks } from './mails.ts';
import { confirmToken, testConfig, unsubscribeToken } from './testing.ts';

const links = mailLinks(testConfig, { confirm: confirmToken, unsubscribe: unsubscribeToken });

Deno.test('mail links point at site pages, with the token in the fragment', () => {
  assertEquals(links.confirmPage, `https://waitlist.example.com/potwierdz/#t=${confirmToken}`);
  assertEquals(links.unsubscribePage, `https://waitlist.example.com/wypisz/#t=${unsubscribeToken}`);
  assertEquals(
    links.unsubscribeEndpoint,
    `https://api.example.com/functions/v1/waitlist-unsubscribe?token=${unsubscribeToken}`,
  );
});

Deno.test('no confirm token, no confirm page', () => {
  assertEquals(mailLinks(testConfig, { confirm: null, unsubscribe: unsubscribeToken }).confirmPage, undefined);
});

Deno.test('the confirmation mail carries the link, the code and the way out in both bodies', () => {
  const mail = confirmationMail('REWI-7K3M-9QZT', links);

  for (const body of [mail.text, mail.html]) {
    assertStringIncludes(body, links.confirmPage!);
    assertStringIncludes(body, 'REWI-7K3M-9QZT');
    assertStringIncludes(body, links.unsubscribePage);
  }
  assertStringIncludes(mail.html, '<html lang="pl">');
});

Deno.test('the code mail has no confirm link', () => {
  const mail = codeMail('REWI-7K3M-9QZT', { ...links, confirmPage: undefined });

  assertStringIncludes(mail.text, 'REWI-7K3M-9QZT');
  assert(!mail.text.includes('/potwierdz/'));
  assertStringIncludes(mail.html, links.unsubscribePage);
});

Deno.test('values are escaped in the HTML body', () => {
  const mail = codeMail('<b>&"', links);

  assertStringIncludes(mail.html, '&lt;b&gt;&amp;&quot;');
  assert(!mail.html.includes('<b>&"'));
});
