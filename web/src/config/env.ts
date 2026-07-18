// Typed access to public (browser-exposed) environment variables.
// NEXT_PUBLIC_* values are inlined at build time.
export const env = {
  /** Base URL of api/common (used once Firebase/backend integration lands). */
  apiBaseUrl: process.env.NEXT_PUBLIC_BASE_URL ?? "http://localhost:8080",
  googleClientId: process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID ?? "",
  /**
   * TEST_MODE (web-standard): NEXT_PUBLIC_TEST_MODE=1 →
   * - GoogleAuthButton navigates straight to /dashboard (no Firebase), and
   * - the API client targets the in-app mock server (/api/mock).
   */
  testMode: process.env.NEXT_PUBLIC_TEST_MODE === "1",
} as const;
