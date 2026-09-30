import { assertEquals } from 'jsr:@std/assert@1';
import { maxOtherLength, parseAnswers } from './survey.ts';

Deno.test('every question answered is kept as sent', () => {
  const answers = {
    trade: ['chimney', 'gas'],
    clients: 'under_50',
    platform: 'android',
    records: ['notebook', 'other_app'],
    records_other: 'Kalendarz Google',
    reminders: 'call',
    lost_clients: 'few',
    would_pay: 'yes',
  };

  assertEquals(parseAnswers(answers), answers);
});

Deno.test('every question is optional', () => {
  assertEquals(parseAnswers({}), {});
});

Deno.test('the "other" text is trimmed, cut and dropped when empty', () => {
  assertEquals(parseAnswers({ trade: ['other'], trade_other: `  ${'x'.repeat(500)} ` }), {
    trade: ['other'],
    trade_other: 'x'.repeat(maxOtherLength),
  });
  assertEquals(parseAnswers({ trade: ['other'], trade_other: '   ' }), { trade: ['other'] });
});

Deno.test('anything the page cannot send is refused', () => {
  for (
    const answers of [
      null,
      'chimney',
      ['chimney'],
      { colour: 'red' },
      { clients: 'thousands' },
      { clients: ['under_50'] },
      { trade: 'chimney' },
      { trade: [] },
      { trade: ['chimney', 'chimney'] },
      { trade: ['chimney'], trade_other: 'szamba' },
      { trade_other: 'szamba' },
      { clients: 'under_50', clients_other: 'dużo' },
      { trade: ['other'], trade_other: 42 },
    ]
  ) {
    assertEquals(parseAnswers(answers), null, JSON.stringify(answers));
  }
});
