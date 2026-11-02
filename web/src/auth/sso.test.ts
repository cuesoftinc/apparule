import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const apiFetch = vi.fn();
vi.mock("@/lib/api", async () => {
  class ApiError extends Error {
    constructor(
      readonly code: string,
      message: string,
      readonly status: number,
    ) {
      super(message);
    }
  }
  return { ApiError, apiFetch: (...a: unknown[]) => apiFetch(...a) };
});

import { ApiError } from "@/lib/api";
import {
  clearSsoClientState,
  exchangeSsoSelectedChannel,
  selectSsoExchangeChannel,
  startGoogleSso,
} from "./sso";

const HANDOFF = "h".repeat(43);

function storedVerifier(): string {
  const raw = window.sessionStorage.getItem("apparule_sso_verifier");
  return JSON.parse(raw ?? "{}").verifier;
}

describe("Google SSO browser flow", () => {
  beforeEach(() => {
    apiFetch.mockReset();
    clearSsoClientState();
  });
  afterEach(() => {
    vi.useRealTimers();
  });

  it("stores a verifier and navigates to the API with its S256 challenge", async () => {
    const assign = vi.fn();
    vi.stubGlobal("location", {
      ...window.location,
      origin: window.location.origin,
      assign,
    });
    await startGoogleSso();
    expect(assign).toHaveBeenCalledOnce();
    const url = new URL(assign.mock.calls[0][0], "http://web.local");
    expect(url.pathname).toBe("/api/v1/auth/sso/google");
    const verifier = storedVerifier();
    expect(verifier).toMatch(/^[A-Za-z0-9_-]{43}$/);
    const digest = await crypto.subtle.digest(
      "SHA-256",
      new TextEncoder().encode(verifier),
    );
    const expected = btoa(String.fromCharCode(...new Uint8Array(digest)))
      .replace(/\+/g, "-")
      .replace(/\//g, "_")
      .replace(/=+$/, "");
    expect(url.searchParams.get("cv")).toBe(expected);
    vi.unstubAllGlobals();
  });

  it("selects the body channel only when a handoff and a verifier both exist", async () => {
    expect(selectSsoExchangeChannel(HANDOFF)).toEqual({ channel: "cookie" });
    vi.stubGlobal("location", { ...window.location, assign: vi.fn() });
    await startGoogleSso();
    vi.unstubAllGlobals();
    expect(selectSsoExchangeChannel(HANDOFF)).toEqual({
      channel: "body",
      handoff: HANDOFF,
      verifier: storedVerifier(),
    });
    expect(selectSsoExchangeChannel(null)).toEqual({ channel: "cookie" });
  });

  it("posts the handoff and verifier with credentials and returns the token", async () => {
    apiFetch.mockResolvedValue({ token: "jwt" });
    const token = await exchangeSsoSelectedChannel({
      channel: "body",
      handoff: HANDOFF,
      verifier: "v".repeat(43),
    });
    expect(token).toBe("jwt");
    expect(apiFetch).toHaveBeenCalledWith("/v1/auth/sso/exchange", {
      method: "POST",
      json: { handoff: HANDOFF, verifier: "v".repeat(43) },
      credentials: "include",
    });
  });

  it("accepts access_token and sends an empty body on the cookie channel", async () => {
    apiFetch.mockResolvedValue({ access_token: "jwt2" });
    expect(await exchangeSsoSelectedChannel({ channel: "cookie" })).toBe(
      "jwt2",
    );
    expect(apiFetch.mock.calls[0][1].json).toEqual({});
  });

  it("never retries a consumed handoff", async () => {
    apiFetch.mockRejectedValue(new ApiError("handoff_invalid", "no", 401));
    await expect(
      exchangeSsoSelectedChannel({ channel: "cookie" }),
    ).rejects.toMatchObject({ status: 401 });
    expect(apiFetch).toHaveBeenCalledTimes(1);
  });

  it("retries a server failure and then succeeds", async () => {
    vi.useFakeTimers();
    apiFetch
      .mockRejectedValueOnce(new ApiError("internal", "boom", 503))
      .mockResolvedValueOnce({ token: "jwt" });
    const pending = exchangeSsoSelectedChannel({ channel: "cookie" });
    await vi.advanceTimersByTimeAsync(1_000);
    await expect(pending).resolves.toBe("jwt");
    expect(apiFetch).toHaveBeenCalledTimes(2);
  });

  it("rejects an exchange that returns no token", async () => {
    apiFetch.mockResolvedValue({});
    await expect(
      exchangeSsoSelectedChannel({ channel: "cookie" }),
    ).rejects.toThrow(/session token/);
  });

  it("clears every apparule_sso_ record", () => {
    window.sessionStorage.setItem("apparule_sso_x", "1");
    window.localStorage.setItem("apparule_sso_y", "1");
    expect(clearSsoClientState()).toBe(true);
    expect(window.sessionStorage.getItem("apparule_sso_x")).toBeNull();
    expect(window.localStorage.getItem("apparule_sso_y")).toBeNull();
  });
});
