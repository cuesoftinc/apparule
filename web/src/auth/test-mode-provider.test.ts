import { beforeEach, describe, expect, it, vi } from "vitest";

const me = vi.fn();
vi.mock("@/models/repositories/account-repo", () => ({
  accountRepo: {
    me: (...a: unknown[]) => me(...a),
  },
}));

import { TestModeAuthProvider } from "./test-mode-provider";

const account = {
  id: "acc-kiki",
  username: "kiki.adeyemi",
  display_name: "Kiki Adeyemi",
};

beforeEach(() => {
  me.mockReset();
  window.sessionStorage.removeItem("apparule.test-session");
});

describe("TestModeAuthProvider (X-1, TEST_MODE)", () => {
  it("signs in with the seeded mock account from /me", async () => {
    me.mockResolvedValue(account);
    const provider = new TestModeAuthProvider();
    const result = await provider.signInWithGoogle();
    expect(result).toEqual({ ok: true, session: { account } });
  });

  it("persists under `apparule.test-session` in sessionStorage (fleet P16)", async () => {
    me.mockResolvedValue(account);
    const provider = new TestModeAuthProvider();
    await provider.signInWithGoogle();
    // Dictated canon 2026-07-21: `<product>.test-session`, sessionStorage,
    // JSON user payload — one shape across the fleet's e2e tooling.
    expect(
      JSON.parse(window.sessionStorage.getItem("apparule.test-session")!),
    ).toEqual(account);
    expect(window.localStorage.getItem("apparule.test-session")).toBeNull();
    await provider.signOut();
  });

  it("an unreachable mock server reads as network_failed, not a throw", async () => {
    me.mockRejectedValue(new Error("mock server down"));
    const provider = new TestModeAuthProvider();
    const result = await provider.signInWithGoogle();
    expect(result).toMatchObject({ ok: false, code: "network_failed" });
    expect(window.sessionStorage.getItem("apparule.test-session")).toBeNull();
  });

  it("restore re-resolves /me so account state is never served stale", async () => {
    me.mockResolvedValue(account);
    const provider = new TestModeAuthProvider();
    await provider.signInWithGoogle();
    const updated = { ...account, display_name: "Kiki A." };
    me.mockResolvedValue(updated);
    expect(await provider.restore()).toEqual({ account: updated });
  });

  it("restore without a session resolves null (flows/auth.md §2: signed out)", async () => {
    me.mockResolvedValue(account);
    const provider = new TestModeAuthProvider();
    expect(await provider.restore()).toBeNull();
    expect(me).not.toHaveBeenCalled();
  });

  it("reads a corrupted session as signed out (flows/auth.md §2: null, never throw)", async () => {
    window.sessionStorage.setItem("apparule.test-session", "{not json");
    const provider = new TestModeAuthProvider();
    expect(await provider.restore()).toBeNull();
    expect(me).not.toHaveBeenCalled();
  });

  it("a failed /me during restore resolves null, never rejects", async () => {
    me.mockResolvedValue(account);
    const provider = new TestModeAuthProvider();
    await provider.signInWithGoogle();
    me.mockRejectedValue(new Error("mock server down"));
    await expect(provider.restore()).resolves.toBeNull();
  });

  it("sign-out clears the session", async () => {
    me.mockResolvedValue(account);
    const provider = new TestModeAuthProvider();
    await provider.signInWithGoogle();
    await provider.signOut();
    expect(window.sessionStorage.getItem("apparule.test-session")).toBeNull();
    expect(await provider.restore()).toBeNull();
  });
});
