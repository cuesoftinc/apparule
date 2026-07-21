// TEST_MODE auth provider — no Firebase dependency. Sign-in resolves the
// seeded mock account (kiki.adeyemi) from the in-app mock server via the
// account repository; a sessionStorage flag makes the session sticky across
// reloads within the tab.
import { accountRepo } from "@/models/repositories/account-repo";
import type { AuthProviderAdapter, AuthSession, SignInResult } from "./types";

const SESSION_FLAG = "apparule.testmode.signedin";

export class TestModeAuthProvider implements AuthProviderAdapter {
  readonly name = "test-mode" as const;

  async signInWithGoogle(): Promise<SignInResult> {
    try {
      const account = await accountRepo.me();
      try {
        window.sessionStorage.setItem(SESSION_FLAG, "1");
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
      window.sessionStorage.removeItem(SESSION_FLAG);
    } catch {
      // ignore
    }
  }

  async restore(): Promise<AuthSession | null> {
    try {
      if (window.sessionStorage.getItem(SESSION_FLAG) !== "1") return null;
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
