"use client";

// /auth/callback: the API redirects here with a one-time handoff code after
// Google sign-in. The code is redeemed once with this tab's verifier, the
// query string is stripped before anything else runs, and the account is
// loaded through the auth context before routing into the app.
import { useCallback, useEffect, useRef, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useAuth } from "@/auth/AuthContext";
import { readCallbackContract } from "@/auth/callback-contract";
import { getSsoCompletionErrorMessage } from "@/auth/oauth-errors";
import {
  clearSsoClientState,
  exchangeSsoSelectedChannel,
  selectSsoExchangeChannel,
  startGoogleSso,
  type SsoExchangeChannel,
} from "@/auth/sso";
import { ApiError } from "@/lib/api";
import { Spinner } from "@/components/ui/Spinner";

const CONTRACT_ERROR =
  "This sign-in response is invalid or no longer supported. Please start sign-in again.";
const CLEANUP_ERROR =
  "This browser could not secure the sign-in callback. Close this tab and try again.";
const ACCOUNT_ERROR = "Sign-in completed, but Apparule could not be reached.";
const RESTART_ERROR = "Google sign-in could not restart. Please try again.";

type Recovery =
  | { kind: "exchange"; selected: SsoExchangeChannel }
  | { kind: "restart" };

export default function AuthCallbackPage() {
  const router = useRouter();
  const { completeSignIn } = useAuth();
  const startedRef = useRef(false);
  const recoveryRef = useRef<Recovery>({ kind: "restart" });
  const [error, setError] = useState<string | null>(null);
  const [retryLabel, setRetryLabel] = useState("Start sign-in again");

  const showError = useCallback(
    (message: string, label: string, recovery: Recovery) => {
      if (recovery.kind === "restart") clearSsoClientState();
      recoveryRef.current = recovery;
      setRetryLabel(label);
      setError(message);
    },
    [],
  );

  // The channel is pinned in the recovery record so a retry never downgrades a body-bound exchange to the cookie.
  const exchangeAndEnter = useCallback(
    async (selected: SsoExchangeChannel) => {
      try {
        const token = await exchangeSsoSelectedChannel(selected);
        const result = await completeSignIn(token);
        if (!result.ok) {
          showError(ACCOUNT_ERROR, "Retry completion", {
            kind: "exchange",
            selected,
          });
          return;
        }
        router.replace("/dashboard");
      } catch (reason) {
        const retryable =
          (reason instanceof ApiError && reason.status >= 500) ||
          reason instanceof TypeError;
        showError(
          getSsoCompletionErrorMessage(reason),
          retryable ? "Retry completion" : "Start sign-in again",
          retryable ? { kind: "exchange", selected } : { kind: "restart" },
        );
      }
    },
    [completeSignIn, router, showError],
  );

  useEffect(() => {
    if (startedRef.current) return;
    startedRef.current = true;

    queueMicrotask(() => {
      const { hash, search, pathname } = window.location;
      try {
        window.history.replaceState(window.history.state, "", pathname);
      } catch {
        showError(CLEANUP_ERROR, "Start sign-in again", { kind: "restart" });
        return;
      }

      const contract = readCallbackContract(search, hash);
      if (contract.kind === "invalid") {
        showError(CONTRACT_ERROR, "Start sign-in again", { kind: "restart" });
        return;
      }
      if (contract.kind === "oauth-error") {
        showError(contract.message, "Start sign-in again", {
          kind: "restart",
        });
        return;
      }

      const selected = selectSsoExchangeChannel(contract.handoff);
      if (!clearSsoClientState()) {
        showError(CLEANUP_ERROR, "Start sign-in again", { kind: "restart" });
        return;
      }
      void exchangeAndEnter(selected);
    });
  }, [exchangeAndEnter, showError]);

  const retry = () => {
    const recovery = recoveryRef.current;
    setError(null);
    if (recovery.kind === "exchange") {
      void exchangeAndEnter(recovery.selected);
      return;
    }
    startGoogleSso().catch(() => {
      showError(RESTART_ERROR, "Start sign-in again", { kind: "restart" });
    });
  };

  if (error) {
    return (
      <main
        id="main"
        tabIndex={-1}
        className="flex flex-1 flex-col items-center justify-center px-6 py-16"
      >
        <div className="flex w-full max-w-sm flex-col items-stretch gap-4 text-center">
          <h1 className="text-title font-semibold text-text">
            Sign-in was interrupted
          </h1>
          <p role="alert" className="text-body text-text-2">
            {error}
          </p>
          <button
            type="button"
            onClick={retry}
            className="h-12 rounded-card border border-border bg-bg-elev px-6 text-body font-semibold text-text"
          >
            {retryLabel}
          </button>
          <Link
            href="/signin"
            onClick={clearSsoClientState}
            className="text-micro text-link underline underline-offset-2"
          >
            Back to sign in
          </Link>
        </div>
      </main>
    );
  }

  return (
    <main
      id="main"
      tabIndex={-1}
      aria-busy="true"
      className="flex flex-1 items-center justify-center py-24"
    >
      <Spinner size={28} kind="gradient" />
      <span className="sr-only">Completing sign-in…</span>
    </main>
  );
}
