// Auth provider abstraction (web-standard TEST_MODE rule): the app talks to
// this interface only. TestModeAuthProvider implements it now;
// FirebaseAuthProvider is added at backend-integration time — X-1 Google-only
// either way (flows/auth.md: exactly one auth CTA).
import type { Account } from "@/models";

export interface AuthSession {
  account: Account;
}

export type SignInResult =
  | { ok: true; session: AuthSession }
  | {
      ok: false;
      /** snake_case, mirrors the error-code style of the API taxonomy. */
      code: "firebase_not_configured" | "popup_dismissed" | "network_failed";
      message: string;
    };

export interface AuthProviderAdapter {
  readonly name: "test-mode" | "firebase";
  /** X-1: Google is the only sign-in method, product-wide. */
  signInWithGoogle(): Promise<SignInResult>;
  signOut(): Promise<void>;
  /** Restore an existing session on app load (SDK/session cache). */
  restore(): Promise<AuthSession | null>;
}
