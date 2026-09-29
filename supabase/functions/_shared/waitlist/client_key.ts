/**
 * A rate-limit key for the caller: HMAC-SHA-256 of the client IP under a
 * secret salt, so the table never holds an address that could be reversed
 * (IPv4 is small enough to brute-force a plain hash). Rows live for a day.
 */
export async function clientKey(request: Request, salt: string): Promise<string> {
  const ip = clientIp(request) ?? 'unknown';
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(salt),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const mac = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(ip));
  return Array.from(new Uint8Array(mac).slice(0, 16), (b) => b.toString(16).padStart(2, '0')).join('');
}

/**
 * Best effort: `cf-connecting-ip` (set by the CDN in front of hosted Supabase),
 * then `x-real-ip`, then the first `x-forwarded-for` hop. The last one can be
 * forged by the caller, which is why the sign-up function also has a global
 * hourly cap; the IP is a hint, not an identity.
 */
export function clientIp(request: Request): string | null {
  const headers = request.headers;
  return headers.get('cf-connecting-ip')?.trim() ||
    headers.get('x-real-ip')?.trim() ||
    headers.get('x-forwarded-for')?.split(',')[0]?.trim() ||
    null;
}
