// SsoAuthProvider: X-1 Google-only sign-in through the API's own SSO flow.
// The API owns the Google round trip and issues its session; this provider
// starts the redirect, keeps the bearer from the handoff exchange in memory
// and restores a reload from the HttpOnly session cookie via /me.
import { setTokenSource } from "@/lib/api";
import { accountRepo } from "@/models/repositories/account-repo";
import { startGoogleSso } from "./sso";
import type { AuthProviderAdapter, AuthSession, SignInResult } from "./types";

export class SsoAuthProvider implements AuthProviderAdapter {
  readonly name = "sso" as const;
  private token: string | null = null;

  constructor() {
    setTokenSource(async () => this.token);
  }

  async signInWithGoogle(): Promise<SignInResult> {
    try {
      await startGoogleSso();
    } catch {
      return {
        ok: false,
        code: "sso_unavailable",
        message: "Google sign-in is unavailable in this browser.",
      };
    }
    // The page navigates away; the callback route finishes sign-in on return.
    return { ok: false, code: "redirecting", message: "Continuing to Google…" };
  }

  async completeSignIn(token: string): Promise<SignInResult> {
    this.token = token;
    try {
      return { ok: true, session: { account: await accountRepo.me() } };
    } catch {
      this.token = null;
      return {
        ok: false,
        code: "network_failed",
        message: "Could not reach Apparule.",
      };
    }
  }

  async signOut(): Promise<void> {
    this.token = null;
    try {
      await fetch("/api/v1/auth/logout", {
        method: "POST",
        credentials: "include",
      });
    } catch {
      // the local session is already cleared
    }
  }

  /** flows/auth.md §2: any failure reads as signed out, never a throw. */
  async restore(): Promise<AuthSession | null> {
    try {
      return { account: await accountRepo.me() };
    } catch {
      return null;
    }
  }
}
