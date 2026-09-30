const e164 = /^\+[1-9][0-9]{7,14}$/;

/**
 * A phone number as people type it, in E.164. Nine digits are a Polish number;
 * spaces, dashes, dots and brackets are dropped, `00` means `+`. Null when the
 * result is not a plausible number (a Polish one must have nine digits).
 */
export function normalizePhone(input: string): string | null {
  let digits = input.trim().replace(/[\s.()-]/g, '');
  if (digits.startsWith('00')) digits = `+${digits.slice(2)}`;
  if (/^[0-9]{9}$/.test(digits)) digits = `+48${digits}`;
  if (/^48[0-9]{9}$/.test(digits)) digits = `+${digits}`;

  if (!e164.test(digits)) return null;
  if (digits.startsWith('+48') && digits.length !== 12) return null;
  return digits;
}
