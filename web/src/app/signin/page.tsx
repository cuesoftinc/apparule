import type { Metadata } from "next";
import { GoogleAuthButton } from "@/components/ui/GoogleAuthButton";

// Single auth screen per flows/auth.md §5 — Google CTA + legal links only
// (X-1: no username/password anywhere, product-wide).
export const metadata: Metadata = {
  title: "Sign in — Apparule",
  description: "Sign in to Apparule with Google",
};

export default function SignInPage() {
  return (
    <main className="flex flex-1 flex-col items-center justify-center px-6 py-16">
      <div className="flex w-full max-w-sm flex-col items-stretch gap-8">
        <header className="flex flex-col items-center gap-2 text-center">
          <h1 className="bg-accent-gradient bg-clip-text text-display font-bold text-transparent">
            Apparule
          </h1>
          <p className="text-body text-text-2">
            Precision measurement meets social fashion
          </p>
        </header>

        <GoogleAuthButton />

        <footer className="text-center text-micro text-text-2">
          By continuing you agree to our{" "}
          <a href="/terms" className="text-link">
            Terms
          </a>{" "}
          and{" "}
          <a href="/privacy" className="text-link">
            Privacy Policy
          </a>
          .
        </footer>
      </div>
    </main>
  );
}
