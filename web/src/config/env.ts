// Typed access to public (browser-exposed) environment variables.
// NEXT_PUBLIC_* values are inlined at build time.
export const env = {
  apiBaseUrl: process.env.NEXT_PUBLIC_BASE_URL ?? "http://localhost:8080",
  googleClientId: process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID ?? "",
} as const;
