import { afterEach, describe, expect, it, vi } from "vitest";

const me = vi.fn();
vi.mock("@/models/repositories/account-repo", () => ({
  accountRepo: { me: (...a: unknown[]) => me(...a) },
}));
const startGoogleSso = vi.fn();
vi.mock("./sso", () => ({ startGoogleSso: () => startGoogleSso() }));
const setTokenSource = vi.fn();
vi.mock("@/lib/api", () => ({
  setTokenSource: (...a: unknown[]) => setTokenSource(...a),
}));

import { SsoAuthProvider } from "./sso-provider";

afterEach(() => {
  me.mockReset();
  startGoogleSso.mockReset();
  vi.unstubAllGlobals();
});

describe("SsoAuthProvider", () => {
  it("reports a redirect after starting Google sign-in", async () => {
    startGoogleSso.mockResolvedValue(undefined);
    const result = await new SsoAuthProvider().signInWithGoogle();
    expect(result).toMatchObject({ ok: false, code: "redirecting" });
  });

  it("reports unavailable when the browser state cannot be set", async () => {
    startGoogleSso.mockRejectedValue(new Error("no storage"));
    const result = await new SsoAuthProvider().signInWithGoogle();
    expect(result).toMatchObject({ ok: false, code: "sso_unavailable" });
  });

  it("serves the exchanged token as the bearer and drops it on failure", async () => {
    const provider = new SsoAuthProvider();
    const source = setTokenSource.mock.calls.at(-1)?.[0] as () => Promise<
      string | null
    >;
    me.mockResolvedValue({ username: "kiki" });
    expect(await provider.completeSignIn("jwt")).toMatchObject({ ok: true });
    expect(await source()).toBe("jwt");
    me.mockRejectedValue(new Error("down"));
    expect(await provider.completeSignIn("jwt2")).toMatchObject({
      ok: false,
      code: "network_failed",
    });
    expect(await source()).toBeNull();
  });

  it("restores from the session cookie and reads a failure as signed out", async () => {
    const provider = new SsoAuthProvider();
    me.mockResolvedValue({ username: "kiki" });
    expect(await provider.restore()).toEqual({ account: { username: "kiki" } });
    me.mockRejectedValue(new Error("401"));
    expect(await provider.restore()).toBeNull();
  });

  it("calls logout with credentials and swallows network errors", async () => {
    const fetchMock = vi.fn().mockRejectedValue(new Error("offline"));
    vi.stubGlobal("fetch", fetchMock);
    await new SsoAuthProvider().signOut();
    expect(fetchMock).toHaveBeenCalledWith("/api/v1/auth/logout", {
      method: "POST",
      credentials: "include",
    });
  });
});
