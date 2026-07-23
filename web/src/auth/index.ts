// Auth module barrel (web-standard shape). Provider selection lives in
// AuthContext (TEST_MODE → TestModeAuthProvider, otherwise StubAuthProvider
// until the FirebaseAuthProvider lands at backend-integration time — X-1
// Google-only either way).

export { AuthProvider, useAuth, type AuthStatus } from "./AuthContext";
export type { AuthProviderAdapter, AuthSession, SignInResult } from "./types";
export { TestModeAuthProvider } from "./test-mode-provider";
export { StubAuthProvider } from "./stub-auth-provider";
