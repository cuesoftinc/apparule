// The only query shapes /auth/callback accepts: a handoff code, or the error
// keys the API puts on a failed redirect. Anything else is invalid.
import { getOAuthRedirectErrorMessage } from "./oauth-errors";

const HANDOFF_PATTERN = /^[A-Za-z0-9_-]{43}$/;
const OAUTH_ERROR_KEYS = new Set(["error", "error_description", "message"]);

export type CallbackContract =
  | { kind: "exchange"; handoff: string | null }
  | { kind: "oauth-error"; message: string }
  | { kind: "invalid" };

export function readCallbackContract(
  search: string,
  hash: string,
): CallbackContract {
  if (hash) return { kind: "invalid" };
  const params = new URLSearchParams(search);
  const keys = [...params.keys()];
  if (keys.length === 0) return { kind: "exchange", handoff: null };

  if (params.has("handoff")) {
    const handoffs = params.getAll("handoff");
    if (keys.some((key) => key !== "handoff")) return { kind: "invalid" };
    if (handoffs.length !== 1 || !HANDOFF_PATTERN.test(handoffs[0])) {
      return { kind: "invalid" };
    }
    return { kind: "exchange", handoff: handoffs[0] };
  }

  if (
    keys.every((key) => OAUTH_ERROR_KEYS.has(key)) &&
    [...new Set(keys)].every((key) => params.getAll(key).length === 1)
  ) {
    const message = getOAuthRedirectErrorMessage(params);
    if (message) return { kind: "oauth-error", message };
  }
  return { kind: "invalid" };
}
