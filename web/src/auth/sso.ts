// Browser side of Google SSO: commit a PKCE-style verifier for this tab, hand
// the browser to the API's Google flow, then redeem the one-time handoff code
// together with the verifier. Everything stays on the web origin through the
// /api proxy so the API's cookies are first-party.
import { ApiError, apiFetch } from "@/lib/api";

const VERIFIER_KEY = "apparule_sso_verifier";
const STORAGE_PREFIX = "apparule_sso_";
const VERIFIER_TTL_MS = 10 * 60 * 1_000;
const EXCHANGE_RETRY_DELAYS_MS = [0, 1_000, 3_000, 7_000];

interface StoredVerifier {
  version: 1;
  verifier: string;
  owner: string;
  createdAt: number;
  expiresAt: number;
}

interface ExchangeResponse {
  token?: string;
  access_token?: string;
}

export type SsoExchangeChannel =
  | { channel: "body"; handoff: string; verifier: string }
  | { channel: "cookie" };

let startInFlight = false;

// A back/forward-cache restore revives the page with the guard still set.
if (typeof window !== "undefined") {
  window.addEventListener("pageshow", (event) => {
    if (event.persisted) startInFlight = false;
  });
}

/** Full-page navigation hook, replaceable in tests. */
export function navigateBrowser(url: string): void {
  window.location.assign(url);
}

/** Commit a verifier for this tab, then send the browser to the API's Google flow. */
export async function startGoogleSso(): Promise<void> {
  if (startInFlight) return;
  if (!clearSsoClientState()) {
    throw new Error("SSO browser state is unavailable.");
  }
  startInFlight = true;
  try {
    const challenge = await commitVerifierChallenge();
    const params = new URLSearchParams({ cv: challenge });
    navigateBrowser(`/api/v1/auth/sso/google?${params.toString()}`);
  } catch (error) {
    clearSsoClientState();
    throw error;
  }
}

async function commitVerifierChallenge(): Promise<string> {
  const createdAt = Date.now();
  const verifier = base64UrlEncode(crypto.getRandomValues(new Uint8Array(32)));
  const record: StoredVerifier = {
    version: 1,
    verifier,
    owner: window.location.origin,
    createdAt,
    expiresAt: createdAt + VERIFIER_TTL_MS,
  };
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(verifier),
  );
  const serialized = JSON.stringify(record);
  window.sessionStorage.setItem(VERIFIER_KEY, serialized);
  if (window.sessionStorage.getItem(VERIFIER_KEY) !== serialized) {
    throw new Error("SSO verifier could not be retained.");
  }
  return base64UrlEncode(new Uint8Array(digest));
}

/** Pin the exchange channel once per attempt: the verifier-bound body when both secrets exist, otherwise the HttpOnly cookie. */
export function selectSsoExchangeChannel(
  handoff: string | null,
): SsoExchangeChannel {
  const verifier = handoff ? readStoredVerifier() : null;
  if (handoff && verifier) return { channel: "body", handoff, verifier };
  return { channel: "cookie" };
}

/** Every retry stays on the selected channel; a rejected body never downgrades to the cookie. */
export async function exchangeSsoSelectedChannel(
  selected: SsoExchangeChannel,
): Promise<string> {
  const body =
    selected.channel === "body"
      ? { handoff: selected.handoff, verifier: selected.verifier }
      : undefined;
  let lastError: unknown;
  for (const delayMs of EXCHANGE_RETRY_DELAYS_MS) {
    if (delayMs > 0) {
      await new Promise((resolve) => window.setTimeout(resolve, delayMs));
    }
    try {
      return await requestExchange(body);
    } catch (error) {
      lastError = error;
      if (!isRetryable(error)) throw error;
    }
  }
  throw lastError instanceof Error
    ? lastError
    : new Error("Google sign-in could not complete. Please try again.");
}

async function requestExchange(
  body: { handoff: string; verifier: string } | undefined,
): Promise<string> {
  const response = await apiFetch<ExchangeResponse>("/v1/auth/sso/exchange", {
    method: "POST",
    json: body ?? {},
    credentials: "include",
  });
  const token = response?.token ?? response?.access_token;
  if (!token) {
    throw new Error(
      "Sign-in did not return a session token. Please try again.",
    );
  }
  return token;
}

function readStoredVerifier(): string | null {
  try {
    const value = window.sessionStorage.getItem(VERIFIER_KEY);
    if (!value) return null;
    const record = JSON.parse(value) as Partial<StoredVerifier>;
    const valid =
      isFreshOwnedRecord(record) &&
      typeof record.verifier === "string" &&
      /^[A-Za-z0-9_-]{43}$/.test(record.verifier);
    return valid ? (record.verifier ?? null) : null;
  } catch {
    return null;
  }
}

function isFreshOwnedRecord(record: Partial<StoredVerifier>): boolean {
  const now = Date.now();
  return (
    record.version === 1 &&
    record.owner === window.location.origin &&
    typeof record.createdAt === "number" &&
    typeof record.expiresAt === "number" &&
    record.createdAt <= now + 60_000 &&
    record.expiresAt > now &&
    record.expiresAt - record.createdAt === VERIFIER_TTL_MS
  );
}

function clearStorage(getStorage: () => Storage): boolean {
  try {
    const storage = getStorage();
    const keys = new Set<string>([VERIFIER_KEY]);
    for (let i = 0; i < storage.length; i += 1) {
      const key = storage.key(i);
      if (key?.startsWith(STORAGE_PREFIX)) keys.add(key);
    }
    for (const key of keys) storage.removeItem(key);
    return [...keys].every((key) => storage.getItem(key) === null);
  } catch {
    return false;
  }
}

/** Clears every client-held SSO record and confirms none remain readable. */
export function clearSsoClientState(): boolean {
  if (typeof window === "undefined") return false;
  startInFlight = false;
  const session = clearStorage(() => window.sessionStorage);
  const local = clearStorage(() => window.localStorage);
  return session && local;
}

function base64UrlEncode(bytes: Uint8Array): string {
  const binary = Array.from(bytes, (b) => String.fromCharCode(b)).join("");
  return btoa(binary)
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

// A fetch that never reached the API throws a TypeError; a consumed or expired handoff is a 401 and is never retried.
function isRetryable(error: unknown): boolean {
  if (error instanceof ApiError) return error.status >= 500;
  return error instanceof TypeError;
}
