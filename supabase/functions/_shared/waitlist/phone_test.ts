import { assertEquals } from 'jsr:@std/assert@1';
import { normalizePhone } from './phone.ts';

Deno.test('Polish numbers as people type them become E.164', () => {
  for (const typed of ['601234567', '601 234 567', '601-234-567', '+48 601 234 567', '48601234567', '0048601234567']) {
    assertEquals(normalizePhone(typed), '+48601234567', typed);
  }
});

Deno.test('foreign numbers in international form are kept', () => {
  assertEquals(normalizePhone('+49 (30) 1234 5678'), '+493012345678');
});

Deno.test('implausible numbers are refused', () => {
  for (const typed of ['', '12', '60123456', '+48 601 234 5678', '601 234 567 ext 2', '+0 123 456 789']) {
    assertEquals(normalizePhone(typed), null, typed);
  }
});
