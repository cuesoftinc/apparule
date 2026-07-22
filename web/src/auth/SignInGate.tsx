"use client";

// SignInGate — the /signin reverse guard (flows/auth.md §2, ratified
// 2026-07-22: "session restore resolves before either surface routes; a
// signed-in user never sees the auth screen"). The web sibling of the
// mobile router's reverse redirect: signed_in → replace("/dashboard");
// restore-in-flight → the same aria-busy spinner gate DashboardShell uses
// (never the CTA); only signed_out renders the auth content. The page
// stays a server component (metadata intact) and wraps its content here.
import { useEffect, type ReactNode } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/auth/AuthContext";
import { Spinner } from "@/components/ui/Spinner";

export function SignInGate({ children }: { children: ReactNode }) {
  const { status } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (status === "signed_in") {
      router.replace("/dashboard");
    }
  }, [status, router]);

  if (status !== "signed_out") {
    // Covers both `loading` (restore in flight — TEST_MODE resolves without
    // network on a sessionStorage miss, so this beat is negligible) and
    // `signed_in` (the replace above is navigating).
    return (
      <div
        aria-busy="true"
        className="flex w-full items-center justify-center py-24"
        data-testid="signin-gate"
      >
        <Spinner size={28} kind="gradient" />
        <span className="sr-only">Loading…</span>
      </div>
    );
  }

  return <>{children}</>;
}
