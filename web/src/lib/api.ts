// HTTP transport for the repository layer (src/models/repositories — the
// ONLY layer that talks to the network, per the web standard's MVC rule).
//
// TEST_MODE (NEXT_PUBLIC_TEST_MODE=1) targets the in-app mock server at
// /api/mock; otherwise api/common at `${env.apiBaseUrl}/api` (Firebase bearer
// tokens attach here at backend-integration time).
import { env } from "@/config/env";

/** Ecosystem error envelope: `{"error": {"code", "message", "details?"}}` (api.md §4). */
export interface ErrorEnvelope {
  error: {
    code: string;
    message: string;
    details?: Record<string, unknown>;
  };
}

export class ApiError extends Error {
  readonly code: string;
  readonly status: number;
  readonly details?: Record<string, unknown>;

  constructor(
    code: string,
    message: string,
    status: number,
    details?: Record<string, unknown>,
  ) {
    super(message);
    this.name = "ApiError";
    this.code = code;
    this.status = status;
    this.details = details;
  }
}

export function apiBasePath(): string {
  return env.testMode ? "/api/mock" : `${env.apiBaseUrl}/api`;
}

export interface ApiRequestInit extends RequestInit {
  /** JSON body convenience — serialized and content-typed automatically. */
  json?: unknown;
}

/**
 * Perform a request against the versioned API surface.
 * `path` is relative to the base, e.g. `/v1/feed`.
 */
export async function apiFetch<T>(
  path: string,
  init: ApiRequestInit = {},
): Promise<T> {
  const { json, headers, ...rest } = init;
  const res = await fetch(`${apiBasePath()}${path}`, {
    ...rest,
    headers: {
      ...(json !== undefined ? { "Content-Type": "application/json" } : {}),
      ...(headers ?? {}),
    },
    ...(json !== undefined ? { body: JSON.stringify(json) } : {}),
  });

  if (res.status === 204) {
    return undefined as T;
  }

  const text = await res.text();
  let parsed: unknown = undefined;
  if (text.length > 0) {
    try {
      parsed = JSON.parse(text);
    } catch {
      parsed = undefined;
    }
  }

  if (!res.ok) {
    const envelope = parsed as ErrorEnvelope | undefined;
    if (envelope && typeof envelope === "object" && envelope.error?.code) {
      throw new ApiError(
        envelope.error.code,
        envelope.error.message,
        res.status,
        envelope.error.details,
      );
    }
    throw new ApiError("unknown_error", `API ${path} failed`, res.status);
  }

  return parsed as T;
}

/** Cursor-paginated list shape (api.md §4 — `?cursor=` + `limit`). */
export interface Page<T> {
  items: T[];
  next_cursor: string | null;
}
