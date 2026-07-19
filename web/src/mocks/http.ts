// Shared plumbing for the mock route handlers (src/app/api/mock/*).
// Errors use the ecosystem envelope with stable snake_case codes (api.md §4).
import { NextResponse } from "next/server";

export class MockApiError extends Error {
  constructor(
    readonly code: string,
    message: string,
    readonly status: number,
    readonly details?: Record<string, unknown>,
  ) {
    super(message);
    this.name = "MockApiError";
  }
}

export function jsonResponse(data: unknown, status = 200): NextResponse {
  return NextResponse.json(data, { status });
}

export function noContent(): NextResponse {
  return new NextResponse(null, { status: 204 });
}

export function errorResponse(error: MockApiError): NextResponse {
  return NextResponse.json(
    {
      error: {
        code: error.code,
        message: error.message,
        ...(error.details ? { details: error.details } : {}),
      },
    },
    { status: error.status },
  );
}

/** Wrap a handler body: MockApiError → envelope; anything else → 500. */
export async function handle(
  fn: () => Promise<NextResponse> | NextResponse,
): Promise<NextResponse> {
  try {
    return await fn();
  } catch (e) {
    if (e instanceof MockApiError) return errorResponse(e);
    return errorResponse(
      new MockApiError(
        "internal",
        e instanceof Error ? e.message : "Internal mock error",
        500,
      ),
    );
  }
}

/**
 * Resolve the acting account. TEST_MODE is signed in as the seeded customer
 * (kiki.adeyemi); tests and the QA loop may act as another seeded user via
 * the `x-mock-actor: <username>` header (e.g. designer flows).
 */
export function actorUsername(request: Request): string {
  return request.headers.get("x-mock-actor") ?? "kiki.adeyemi";
}

export async function readJson<T>(request: Request): Promise<T> {
  try {
    return (await request.json()) as T;
  } catch {
    throw new MockApiError("validation_failed", "Body must be JSON", 422);
  }
}

/** `?limit=` parsing (api.md §4): default 50, max 100. */
export function parseLimit(url: URL): number {
  const limitRaw = Number(url.searchParams.get("limit") ?? "50");
  return Math.min(
    Number.isFinite(limitRaw) && limitRaw > 0 ? Math.floor(limitRaw) : 50,
    100,
  );
}

/** Cursor pagination (api.md §4): `?cursor=` + `limit` default 50, max 100. */
export function paginate<T>(
  items: T[],
  url: URL,
): { items: T[]; next_cursor: string | null } {
  const limit = parseLimit(url);
  const cursorRaw = url.searchParams.get("cursor");
  let offset = 0;
  if (cursorRaw) {
    const parsed = Number(
      Buffer.from(cursorRaw, "base64url").toString("utf8"),
    );
    if (Number.isFinite(parsed) && parsed >= 0) offset = parsed;
  }
  const slice = items.slice(offset, offset + limit);
  const nextOffset = offset + limit;
  return {
    items: slice,
    next_cursor:
      nextOffset < items.length
        ? Buffer.from(String(nextOffset), "utf8").toString("base64url")
        : null,
  };
}
