"use client";

// Branded error boundary — the token-styled counterpart to not-found.tsx
// (system QA: an uncaught render error previously fell through to Next's
// unstyled default). Retry re-renders the segment; the quiet link goes home.
import Link from "next/link";
import { AlertTriangle } from "lucide-react";
import { Button } from "@/components/ui/Button";

export default function ErrorPage({
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <main
      id="main"
      tabIndex={-1}
      className="flex min-h-screen flex-col items-center justify-center gap-4 bg-bg px-6 text-center"
    >
      <span className="bg-accent-gradient bg-clip-text text-title font-bold text-transparent">
        Apparule
      </span>
      <span className="grid size-14 place-items-center rounded-pill border border-border text-warn">
        <AlertTriangle size={28} aria-hidden />
      </span>
      <h1 className="text-body-lg font-semibold text-text">
        Something went wrong
      </h1>
      <p className="max-w-sm text-body text-text-2">
        An unexpected error interrupted this screen — your data is safe.
      </p>
      <div className="flex items-center gap-2">
        <Button kind="gradient-primary" onClick={() => reset()}>
          Try again
        </Button>
        <Link
          href="/"
          className="inline-flex h-11 items-center justify-center whitespace-nowrap rounded-card border border-border bg-bg-elev px-4 text-body font-semibold text-text"
        >
          Back home
        </Link>
      </div>
    </main>
  );
}
