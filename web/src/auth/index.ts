// Auth module barrel (web-standard shape). Provider selection lives in
// AuthContext (TEST_MODE → TestModeAuthProvider, otherwise the
// SsoAuthProvider, X-1 Google-only either way).

export { AuthProvider, useAuth, type AuthStatus } from "./AuthContext";
export type { AuthProviderAdapter, AuthSession, SignInResult } from "./types";
export { TestModeAuthProvider } from "./test-mode-provider";
export { SsoAuthProvider } from "./sso-provider";
