import type { Metadata } from "next";
import { SignInGate } from "@/auth/SignInGate";
import { getOAuthRedirectErrorMessage } from "@/auth/oauth-errors";
import { GoogleAuthButton } from "@/components/ui/GoogleAuthButton";

// Single auth screen per flows/auth.md §5 — Google CTA + legal links only
// (X-1: no username/password anywhere, product-wide). SignInGate is the
// flows/auth.md §2 reverse guard: a signed-in visitor is replaced to
// /dashboard and never sees this screen.
export const metadata: Metadata = {
  title: "Sign in — Apparule",
  description: "Sign in to Apparule with Google",
};

export default async function SignInPage({
  searchParams,
}: {
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}) {
  const query = await searchParams;
  const params = new URLSearchParams();
  for (const key of ["error", "error_description", "message"]) {
    const value = query[key];
    if (typeof value === "string") params.set(key, value);
  }
  const failure = getOAuthRedirectErrorMessage(params);
  return (
    <main
      id="main"
      tabIndex={-1}
      className="flex flex-1 flex-col items-center justify-center px-6 py-16"
    >
      <SignInGate>
        <div className="flex w-full max-w-sm flex-col items-stretch gap-8">
          <header className="flex flex-col items-center gap-2 text-center">
            <h1 className="bg-accent-gradient bg-clip-text text-display font-bold text-transparent">
              Apparule
            </h1>
            <p className="text-body text-text-2">
              Precision measurement meets social fashion
            </p>
          </header>

          {failure ? (
            <p role="alert" className="text-center text-caption text-text-2">
              {failure}
            </p>
          ) : null}

          <GoogleAuthButton />

          {/* Inline links in a text block carry a persistent underline —
            color alone can't distinguish them (WCAG 1.4.1; axe
            link-in-text-block, 2026-07-21 audit). */}
          <footer className="text-center text-micro text-text-2">
            By continuing you agree to our{" "}
            <a
              href="https://terms.cuesoft.io"
              target="_blank"
              rel="noreferrer"
              className="text-link underline underline-offset-2"
            >
              Terms
            </a>{" "}
            and{" "}
            <a
              href="https://privacy.cuesoft.io"
              target="_blank"
              rel="noreferrer"
              className="text-link underline underline-offset-2"
            >
              Privacy Policy
            </a>
            .
          </footer>
        </div>
      </SignInGate>
    </main>
  );
}
