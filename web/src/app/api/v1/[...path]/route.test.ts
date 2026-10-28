// @vitest-environment node

import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { GET, POST } from "./route";

const params = (path: string[]) => ({ params: Promise.resolve({ path }) });

describe("/api/v1 proxy (system-design.md §7.1)", () => {
  const calls: Array<{ url: string; init: RequestInit }> = [];

  beforeEach(() => {
    process.env.API_URL = "http://common:8080";
    process.env.UPLOADS_URL = "http://uploads:8082";
    vi.stubGlobal(
      "fetch",
      vi.fn(async (url: string, init: RequestInit) => {
        calls.push({ url, init });
        return new Response(JSON.stringify({ ok: true }), {
          status: 201,
          headers: {
            "content-type": "application/json",
            "retry-after": "7",
            "set-cookie": "x=1",
          },
        });
      }),
    );
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    calls.length = 0;
  });

  it("sends API calls to common with the auth and idempotency headers", async () => {
    const response = await POST(
      new Request("http://web.local/api/v1/me/sessions?x=1", {
        method: "POST",
        headers: {
          Authorization: "Bearer t",
          "Idempotency-Key": "k",
          "Content-Type": "application/json",
          Cookie: "session=secret",
        },
        body: JSON.stringify({ input_height_cm: 168 }),
      }),
      params(["me", "sessions"]),
    );
    expect(calls[0].url).toBe("http://common:8080/api/v1/me/sessions?x=1");
    const sent = calls[0].init.headers as Headers;
    expect(sent.get("authorization")).toBe("Bearer t");
    expect(sent.get("idempotency-key")).toBe("k");
    expect(sent.get("cookie")).toBe("session=secret");
    expect(response.status).toBe(201);
    expect(response.headers.get("retry-after")).toBe("7");
    expect(response.headers.get("set-cookie")).toBe("x=1");
  });

  it("keeps the session cookie away from the uploads gateway", async () => {
    await POST(
      new Request("http://web.local/api/v1/uploads", {
        method: "POST",
        headers: { "Upload-Ticket": "v1.a.b", Cookie: "session=secret" },
        body: "file",
      }),
      params(["uploads"]),
    );
    expect((calls[0].init.headers as Headers).get("cookie")).toBeNull();
  });

  it("passes the Google redirect and its state cookie through untouched", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(async () => {
        const headers = new Headers({ location: "https://accounts.example/o" });
        headers.append("set-cookie", "state=a; HttpOnly");
        headers.append("set-cookie", "other=b");
        return new Response(null, { status: 302, headers });
      }),
    );
    const response = await GET(
      new Request("http://web.local/api/v1/auth/sso/google?cv=abc"),
      params(["auth", "sso", "google"]),
    );
    expect(response.status).toBe(302);
    expect(response.headers.get("location")).toBe("https://accounts.example/o");
    expect(response.headers.getSetCookie()).toEqual([
      "state=a; HttpOnly",
      "other=b",
    ]);
  });

  it("sends uploads to the gateway with the ticket", async () => {
    await POST(
      new Request("http://web.local/api/v1/uploads", {
        method: "POST",
        headers: { "Upload-Ticket": "v1.a.b" },
        body: "file",
      }),
      params(["uploads"]),
    );
    expect(calls[0].url).toBe("http://uploads:8082/api/v1/uploads");
    expect((calls[0].init.headers as Headers).get("upload-ticket")).toBe(
      "v1.a.b",
    );
  });

  it("answers 502 in the error envelope when the backend is down", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(async () => Promise.reject(new Error("ECONNREFUSED"))),
    );
    const response = await GET(
      new Request("http://web.local/api/v1/feed"),
      params(["feed"]),
    );
    expect(response.status).toBe(502);
    expect((await response.json()).error.code).toBe("backend_unavailable");
  });
});
