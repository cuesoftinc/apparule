"use client";

// Auth controller — owns auth state; views render from it (MVC rule).
// Provider selection: TEST_MODE → TestModeAuthProvider; otherwise the
// Firebase stub until backend integration lands.
import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import { env } from "@/config/env";
import type { Account } from "@/models";
import type { AuthProviderAdapter, SignInResult } from "./types";
import { TestModeAuthProvider } from "./test-mode-auth-provider";
import { StubAuthProvider } from "./stub-auth-provider";

export type AuthStatus = "loading" | "signed_out" | "signed_in";

interface AuthContextValue {
  status: AuthStatus;
  account: Account | null;
  providerName: AuthProviderAdapter["name"];
  signInWithGoogle: () => Promise<SignInResult>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

function createProvider(): AuthProviderAdapter {
  return env.testMode ? new TestModeAuthProvider() : new StubAuthProvider();
}

export function AuthProvider({ children }: { children: ReactNode }) {
  // Lazy state init keeps the provider instance stable across renders.
  const [provider] = useState<AuthProviderAdapter>(createProvider);

  const [status, setStatus] = useState<AuthStatus>("loading");
  const [account, setAccount] = useState<Account | null>(null);

  useEffect(() => {
    let cancelled = false;
    provider.restore().then((session) => {
      if (cancelled) return;
      if (session) {
        setAccount(session.account);
        setStatus("signed_in");
      } else {
        setStatus("signed_out");
      }
    });
    return () => {
      cancelled = true;
    };
  }, [provider]);

  const signInWithGoogle = useCallback(async (): Promise<SignInResult> => {
    const result = await provider.signInWithGoogle();
    if (result.ok) {
      setAccount(result.session.account);
      setStatus("signed_in");
    }
    return result;
  }, [provider]);

  const signOut = useCallback(async () => {
    await provider.signOut();
    setAccount(null);
    setStatus("signed_out");
  }, [provider]);

  const value = useMemo(
    () => ({
      status,
      account,
      providerName: provider.name,
      signInWithGoogle,
      signOut,
    }),
    [status, account, provider.name, signInWithGoogle, signOut],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within <AuthProvider>");
  return ctx;
}
