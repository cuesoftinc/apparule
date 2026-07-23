// TEST_MODE auth provider — no Firebase dependency. Sign-in resolves the
// seeded mock account (kiki.adeyemi) from the in-app mock server via the
// account repository; a sessionStorage entry makes the session sticky across
// reloads within the tab.
import { accountRepo } from "@/models/repositories/account-repo";
import type { AuthProviderAdapter, AuthSession, SignInResult } from "./types";

// Fleet P16 key convention (dictated canon 2026-07-21): `<product>.test-session`
// in sessionStorage, JSON user payload — one shape across the fleet's e2e
// tooling. The payload is the account snapshot at sign-in; restore still
// re-resolves /me so account-state changes (e.g. designer onboarding) are
// never served stale.
const SESSION_KEY = "apparule.test-session";

export class TestModeAuthProvider implements AuthProviderAdapter {
  readonly name = "test-mode" as const;

  async signInWithGoogle(): Promise<SignInResult> {
    try {
      const account = await accountRepo.me();
      try {
        window.sessionStorage.setItem(SESSION_KEY, JSON.stringify(account));
      } catch {
        // storage unavailable — session just won't survive a reload
      }
      return { ok: true, session: { account } };
    } catch {
      return {
        ok: false,
        code: "network_failed",
        message: "Could not reach the mock server.",
      };
    }
  }

  async signOut(): Promise<void> {
    try {
      window.sessionStorage.removeItem(SESSION_KEY);
    } catch {
      // ignore
    }
  }

  async restore(): Promise<AuthSession | null> {
    try {
      const raw = window.sessionStorage.getItem(SESSION_KEY);
      if (!raw) return null;
      // flows/auth.md §2: a corrupted session reads as signed out, never a
      // throw. The payload is a marker, not trusted account state — /me is.
      JSON.parse(raw);
    } catch {
      return null;
    }
    try {
      const account = await accountRepo.me();
      return { account };
    } catch {
      return null;
    }
  }
}
