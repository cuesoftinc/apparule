// Branded 404 — before this the router fell through to Next's default
// error shell (system QA finding: off-brand, no tokens, no way home).
// Same anatomy as the EmptyState masters: icon · one-line · one CTA.
import Link from "next/link";
import { Compass } from "lucide-react";

export default function NotFound() {
  return (
    <main
      id="main"
      tabIndex={-1}
      className="flex min-h-screen flex-col items-center justify-center gap-4 bg-bg px-6 text-center"
    >
      <span className="bg-accent-gradient bg-clip-text text-title font-bold text-transparent">
        Apparule
      </span>
      <span className="grid size-14 place-items-center rounded-pill border border-border text-text-2">
        <Compass size={28} aria-hidden />
      </span>
      <h1 className="text-body-lg font-semibold text-text">
        This page doesn&apos;t exist
      </h1>
      <p className="max-w-sm text-body text-text-2">
        The link may be old, or the outfit may have been taken down.
      </p>
      <Link
        href="/"
        className="inline-flex h-11 items-center justify-center whitespace-nowrap rounded-card bg-accent-gradient px-4 text-body font-semibold text-on-accent"
      >
        Back to Apparule
      </Link>
    </main>
  );
}
