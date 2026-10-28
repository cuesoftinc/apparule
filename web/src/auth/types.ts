// Auth provider abstraction (web-standard TEST_MODE rule): the app talks to
// this interface only: TestModeAuthProvider under TEST_MODE,
// SsoAuthProvider against the real backend, X-1 Google-only either way
// (flows/auth.md: exactly one auth CTA).
import type { Account } from "@/models";

export interface AuthSession {
  account: Account;
}

export type SignInResult =
  | { ok: true; session: AuthSession }
  | {
      ok: false;
      /** snake_case, mirrors the error-code style of the API taxonomy. */
      code: "sso_unavailable" | "redirecting" | "network_failed";
      message: string;
    };

export interface AuthProviderAdapter {
  readonly name: "test-mode" | "sso";
  /** X-1: Google is the only sign-in method, product-wide. */
  signInWithGoogle(): Promise<SignInResult>;
  /** Finish a redirect sign-in with the bearer from the handoff exchange. */
  completeSignIn?(token: string): Promise<SignInResult>;
  signOut(): Promise<void>;
  /**
   * Restore an existing session on app load (session cookie).
   * Contract (flows/auth.md §2, ratified 2026-07-22): implementations
   * resolve `null` on any failure and MUST NOT reject — a failed restore
   * reads as signed out. AuthContext still catches as a second net.
   */
  restore(): Promise<AuthSession | null>;
}
