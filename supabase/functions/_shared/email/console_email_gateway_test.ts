import { assert, assertStringIncludes } from 'jsr:@std/assert@1';
import { ConsoleEmailGateway } from './console_email_gateway.ts';
import { emailGatewayContract } from './email_gateway_contract.ts';

emailGatewayContract('ConsoleEmailGateway', () => {
  const gateway = new ConsoleEmailGateway(() => {});
  return { gateway, lastDelivered: () => gateway.sent.at(-1)! };
});

Deno.test('ConsoleEmailGateway prints the text body, so local links can be clicked', async () => {
  const lines: string[] = [];
  const gateway = new ConsoleEmailGateway((line) => lines.push(line));

  await gateway.send({
    from: { email: 'lista@example.com' },
    to: { email: 'jan@example.com' },
    subject: 'Potwierdź zapis',
    text: 'Kliknij: http://localhost:8080/potwierdz/#t=abc',
    html: '',
  });

  assertStringIncludes(lines[0], 'To: jan@example.com');
  assert(!lines[0].includes('Reply-To:'));
  assertStringIncludes(lines[0], 'http://localhost:8080/potwierdz/#t=abc');
});
