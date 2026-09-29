/**
 * Confirm and unsubscribe tokens are 32 random bytes in unpadded base64url
 * (43 characters, see `public.waitlist_random_token`). Anything else is
 * refused before it reaches the database or a Location header.
 */
export function isToken(value: unknown): value is string {
  return typeof value === 'string' && /^[A-Za-z0-9_-]{43}$/.test(value);
}
