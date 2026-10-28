/**
 * /api/v1/* proxy: the browser talks only to the web origin, and this
 * route handler forwards to the backend the way the load balancer does in
 * cloud (system-design.md §7.1): /api/v1/uploads to api/uploads,
 * everything else to api/common. The URLs are read per request
 * (API_URL, UPLOADS_URL), so one build runs in compose and cloud.
 *
 * Server-side code, not a view: no auth logic here. The bearer token, the
 * upload ticket, the session cookie and the SSO redirects pass through
 * untouched and the services check them.
 */

import { serverEnv } from "@/config/env";

export const dynamic = "force-dynamic";

/** Request headers the backend contract uses (engineering.md §CORS). */
const FORWARD_REQUEST = [
  "authorization",
  "cookie",
  "origin",
  "sec-fetch-site",
  "user-agent",
  "x-forwarded-for",
  "content-type",
  "idempotency-key",
  "upload-ticket",
  "x-request-id",
];
/** Response headers the client reads. */
const FORWARD_RESPONSE = [
  "content-type",
  "retry-after",
  "x-request-id",
  "content-disposition",
  "location",
];

const proxy = async (
  request: Request,
  { params }: { params: Promise<{ path: string[] }> },
) => {
  const { path } = await params;
  const { apiUrl, uploadsUrl } = serverEnv();
  const base = path[0] === "uploads" ? uploadsUrl : apiUrl;
  const incoming = new URL(request.url);
  const target = `${base}/api/v1/${path.map(encodeURIComponent).join("/")}${incoming.search}`;

  const headers = new Headers();
  for (const name of FORWARD_REQUEST) {
    const value = request.headers.get(name);
    if (value) headers.set(name, value);
  }

  // The uploads gateway authenticates by ticket and never sees the session cookie.
  if (path[0] === "uploads") headers.delete("cookie");

  const hasBody = request.method !== "GET" && request.method !== "HEAD";
  let upstream: Response;
  try {
    upstream = await fetch(target, {
      method: request.method,
      headers,
      body: hasBody ? request.body : undefined,
      // Stream the body (two 10 MB photos) instead of buffering.
      ...(hasBody ? { duplex: "half" } : {}),
      cache: "no-store",
      redirect: "manual",
    } as RequestInit);
  } catch {
    return Response.json(
      {
        error: {
          code: "backend_unavailable",
          message: "The Apparule API is not reachable",
          details: {},
        },
      },
      { status: 502 },
    );
  }

  const responseHeaders = new Headers();
  for (const name of FORWARD_RESPONSE) {
    const value = upstream.headers.get(name);
    if (value) responseHeaders.set(name, value);
  }
  for (const cookie of upstream.headers.getSetCookie()) {
    responseHeaders.append("set-cookie", cookie);
  }
  return new Response(upstream.body, {
    status: upstream.status,
    headers: responseHeaders,
  });
};

export const GET = proxy;
export const POST = proxy;
export const PUT = proxy;
export const PATCH = proxy;
export const DELETE = proxy;
