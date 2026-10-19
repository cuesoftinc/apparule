// FirebaseAuthProvider: X-1 Google-only sign-in against Firebase Auth.
// api/common verifies the ID token on every request and creates the account
// on first sign-in (flows/auth.md §3), so this provider owns the browser
// session and the bearer token, then resolves /me for the account.
//
// Local runs point at the Auth emulator (NEXT_PUBLIC_FIREBASE_AUTH_EMULATOR_HOST),
// whose Google popup lets you pick or invent an account.
import { type FirebaseApp, getApps, initializeApp } from "firebase/app";
import {
  type Auth,
  connectAuthEmulator,
  getAuth,
  getRedirectResult,
  GoogleAuthProvider,
  onAuthStateChanged,
  signInWithPopup,
  signInWithRedirect,
  signOut,
} from "firebase/auth";
import { env } from "@/config/env";
import { setTokenSource } from "@/lib/api";
import { accountRepo } from "@/models/repositories/account-repo";
import type { AuthProviderAdapter, AuthSession, SignInResult } from "./types";

/**
 * In-app browsers (Instagram, X, TikTok webviews) block popups — likely
 * for a social app — so sign-in falls back to a redirect there
 * (flows/auth.md §4).
 */
function inAppBrowser(): boolean {
  if (typeof navigator === "undefined") return false;
  return /Instagram|FBAN|FBAV|Twitter|TikTok|Line\//i.test(navigator.userAgent);
}

export class FirebaseAuthProvider implements AuthProviderAdapter {
  readonly name = "firebase" as const;
  private readonly auth: Auth;
  private readonly restored: Promise<void>;

  constructor() {
    const { firebase } = env;
    // A local emulator run needs no real project or key.
    const app: FirebaseApp =
      getApps()[0] ??
      initializeApp({
        apiKey: firebase.apiKey || "local-emulator",
        // The emulator serves the popup itself but the SDK still wants a domain.
        authDomain:
          firebase.authDomain ||
          (firebase.authEmulatorHost ? "localhost" : undefined),
        projectId: firebase.projectId || "demo-apparule",
      });
    this.auth = getAuth(app);
    if (firebase.authEmulatorHost) {
      connectAuthEmulator(this.auth, `http://${firebase.authEmulatorHost}`, {
        disableWarnings: true,
      });
    }
    // Firebase restores a persisted session asynchronously; the first
    // auth-state event marks the snapshot as trustworthy.
    this.restored = new Promise((resolve) => {
      const stop = onAuthStateChanged(this.auth, () => {
        stop();
        resolve();
      });
    });
    setTokenSource(() => this.idToken());
  }

  private async idToken(): Promise<string | null> {
    await this.restored;
    // getIdToken refreshes an expired token transparently.
    return (await this.auth.currentUser?.getIdToken()) ?? null;
  }

  async signInWithGoogle(): Promise<SignInResult> {
    const provider = new GoogleAuthProvider();
    provider.setCustomParameters({ prompt: "select_account" });
    try {
      if (inAppBrowser()) {
        await signInWithRedirect(this.auth, provider);
        // The page navigates away; restore() finishes on return.
        return {
          ok: false,
          code: "popup_dismissed",
          message: "Continuing in the browser…",
        };
      }
      await signInWithPopup(this.auth, provider);
    } catch (e) {
      const code = (e as { code?: string }).code ?? "";
      if (
        code === "auth/popup-closed-by-user" ||
        code === "auth/cancelled-popup-request"
      ) {
        return {
          ok: false,
          code: "popup_dismissed",
          message: "Sign-in was cancelled.",
        };
      }
      if (code === "auth/popup-blocked") {
        await signInWithRedirect(this.auth, provider);
        return {
          ok: false,
          code: "popup_dismissed",
          message: "Continuing in the browser…",
        };
      }
      return {
        ok: false,
        code: "network_failed",
        message: "Could not reach Google sign-in.",
      };
    }
    try {
      return { ok: true, session: { account: await accountRepo.me() } };
    } catch {
      await signOut(this.auth).catch(() => undefined);
      return {
        ok: false,
        code: "network_failed",
        message: "Could not reach Apparule.",
      };
    }
  }

  async signOut(): Promise<void> {
    await signOut(this.auth);
  }

  /** flows/auth.md §2: any failure reads as signed out, never a throw. */
  async restore(): Promise<AuthSession | null> {
    try {
      await getRedirectResult(this.auth).catch(() => null);
      await this.restored;
      if (!this.auth.currentUser) return null;
      return { account: await accountRepo.me() };
    } catch {
      return null;
    }
  }
}
