/** Small helpers shared by the public (no-JWT) edge functions. */

/**
 * CORS for browser calls from the static sites. Only the listed origins get
 * the allow headers; requests without an Origin (mail providers' one-click
 * unsubscribe, curl) are not browser requests and need none.
 */
export function corsHeaders(request: Request, allowedOrigins: readonly string[]): Record<string, string> {
  const origin = request.headers.get('origin');
  if (origin === null || !allowedOrigins.includes(origin)) return {};
  return {
    'access-control-allow-origin': origin,
    'access-control-allow-methods': 'POST, OPTIONS',
    'access-control-allow-headers': 'content-type',
    'access-control-max-age': '86400',
    'vary': 'origin',
  };
}

/** True when a browser sent the request from a page we do not serve. */
export function isForeignOrigin(request: Request, allowedOrigins: readonly string[]): boolean {
  const origin = request.headers.get('origin');
  return origin !== null && !allowedOrigins.includes(origin);
}

export function json(body: unknown, status: number, headers: Record<string, string> = {}): Response {
  return Response.json(body, { status, headers: { 'cache-control': 'no-store', ...headers } });
}

/**
 * Reads a JSON object body of at most [maxBytes]. Returns null for anything
 * else (wrong type, too large, not JSON, not an object).
 */
export async function readJsonObject(
  request: Request,
  maxBytes = 4096,
): Promise<Record<string, unknown> | null> {
  if (!(request.headers.get('content-type') ?? '').startsWith('application/json')) return null;
  const bytes = await readAtMost(request, maxBytes);
  if (bytes === null) return null;
  try {
    const value = JSON.parse(new TextDecoder().decode(bytes));
    return typeof value === 'object' && value !== null && !Array.isArray(value) ? value : null;
  } catch {
    return null;
  }
}

/**
 * The body's bytes, or null once they pass [maxBytes]. Stops reading there, so
 * an oversized or endless body costs [maxBytes] of memory, not its full size.
 */
async function readAtMost(request: Request, maxBytes: number): Promise<Uint8Array | null> {
  if (Number(request.headers.get('content-length')) > maxBytes) return null;
  if (request.body === null) return new Uint8Array();
  const reader = request.body.getReader();
  const chunks: Uint8Array[] = [];
  let size = 0;
  for (;;) {
    const { done, value } = await reader.read();
    if (done) break;
    size += value.byteLength;
    if (size > maxBytes) {
      await reader.cancel();
      return null;
    }
    chunks.push(value);
  }
  const bytes = new Uint8Array(size);
  let offset = 0;
  for (const chunk of chunks) {
    bytes.set(chunk, offset);
    offset += chunk.byteLength;
  }
  return bytes;
}
