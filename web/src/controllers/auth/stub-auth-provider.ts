// Placeholder provider for non-TEST_MODE builds until Firebase integration
// lands (no Firebase dependency yet by design). Sign-in reports that the
// backend isn't wired; the UI surfaces "Connect Firebase at integration".
import type {
  AuthProviderAdapter,
  AuthSession,
  SignInResult,
} from "./types";

export class StubAuthProvider implements AuthProviderAdapter {
  readonly name = "firebase" as const;

  async signInWithGoogle(): Promise<SignInResult> {
    return {
      ok: false,
      code: "firebase_not_configured",
      message: "Connect Firebase at integration",
    };
  }

  async signOut(): Promise<void> {
    // nothing to clear
  }

  async restore(): Promise<AuthSession | null> {
    return null;
  }
}
