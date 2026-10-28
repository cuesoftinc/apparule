// Typed access to environment switches (web standard: env access goes
// through this module only). NEXT_PUBLIC_* values are inlined at build time.
//
// NEXT_PUBLIC_TEST_MODE=true puts the app in TEST_MODE: GoogleAuthButton
// navigates straight to the dashboard (no Google redirect) and the API client
// targets the in-app mock server (/api/mock/v1).
//
// Otherwise the app runs against the real backend (system-design.md §7):
// Google sign-in through the API's SSO flow (X-1) and /api/v1, which the server-side proxy
// (src/app/api/v1) forwards to api/common, and /api/v1/uploads to
// api/uploads. The API URLs are read at request time on the server, so
// one image runs anywhere.
const testMode = process.env.NEXT_PUBLIC_TEST_MODE === "true";

export const env = {
  /**
   * TEST_MODE (web-standard): NEXT_PUBLIC_TEST_MODE=true →
   * - GoogleAuthButton navigates straight to /dashboard (no Google redirect), and
   * - the API client targets the in-app mock server (/api/mock).
   */
  testMode,
} as const;

// A production server listens on 8080 itself, so a localhost default there loops back into this proxy.
const localDefault = (url: string) =>
  process.env.NODE_ENV === "production" ? undefined : url;

/**
 * Server-only: where the /api/v1 proxy forwards. Read per request so the
 * same build serves compose (http://common:8080) and cloud.
 */
export const serverEnv = () => ({
  apiUrl: process.env.API_URL ?? localDefault("http://localhost:8080"),
  uploadsUrl: process.env.UPLOADS_URL ?? localDefault("http://localhost:8082"),
});
