// Messages for the error codes the API puts on the sign-in redirect and for
// a failed handoff exchange.
import { ApiError } from "@/lib/api";

const OAUTH_ERROR_MESSAGES = new Map<string, string>([
  [
    "access_denied",
    "Google sign-in was cancelled. You can try again when you are ready.",
  ],
  ["missing_state", "Your sign-in session expired. Please try again."],
  [
    "invalid_state",
    "Your sign-in session could not be verified. Please try again.",
  ],
  ["expired_state", "Your sign-in session expired. Please try again."],
  ["missing_code", "Google did not complete sign-in. Please try again."],
  [
    "sso_failed",
    "Google sign-in is temporarily unavailable. Please try again.",
  ],
  [
    "server_error",
    "Google sign-in is temporarily unavailable. Please try again.",
  ],
  [
    "temporarily_unavailable",
    "Google sign-in is temporarily unavailable. Please try again.",
  ],
  [
    "account_disabled",
    "This account has been disabled. Contact support if this is unexpected.",
  ],
]);

const DEFAULT_OAUTH_ERROR =
  "Google sign-in could not be completed. Please try again.";

export function getOAuthRedirectErrorMessage(
  searchParams: URLSearchParams,
): string | null {
  const code = searchParams.get("error")?.trim().toLowerCase();
  const hasDetail =
    Boolean(searchParams.get("error_description")?.trim()) ||
    Boolean(searchParams.get("message")?.trim());
  if (!code && !hasDetail) return null;
  return (code && OAUTH_ERROR_MESSAGES.get(code)) || DEFAULT_OAUTH_ERROR;
}

export function getSsoCompletionErrorMessage(error: unknown): string {
  if (error instanceof ApiError) {
    if (error.code === "handoff_invalid") {
      return "Your sign-in session expired or was already used. Please try again.";
    }
    if (error.status >= 500) {
      return "Google sign-in is temporarily unavailable. Please try again.";
    }
  }
  if (error instanceof TypeError) {
    return "We could not reach Apparule. Check your connection and try again.";
  }
  return DEFAULT_OAUTH_ERROR;
}
