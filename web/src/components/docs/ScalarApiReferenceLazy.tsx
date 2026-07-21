"use client";

// Lazy boundary for the Scalar embed (perf audit 2026-07-21, P10 —
// fleet-uniform across apparule/expendit/upstat): @scalar/api-reference-react
// is the app's single heaviest dependency (~0.9MB encoded / ~3.2MB decoded
// of route JS), so `next/dynamic` with `ssr: false` splits it out of
// /docs/api's first-load bundle — the marketing chrome (nav SSR'd by the
// page) hydrates without downloading or parsing Scalar, and the reference
// streams in right after. The placeholder reserves the embed's viewport
// slice (100dvh minus the sticky nav, via --scalar-custom-header-height
// set by the page on <main>) so the swap-in shifts no layout (audit:
// CLS 0.169 on this route). Theme forcing, the hidden theme toggle and
// `showDeveloperTools: "never"` live in ScalarApiReference — unchanged.

import dynamic from "next/dynamic";

export const ScalarApiReferenceLazy = dynamic(
  () => import("./ScalarApiReference").then((m) => m.ScalarApiReference),
  {
    ssr: false,
    loading: () => (
      <div
        role="status"
        className="flex min-h-[calc(100dvh-var(--scalar-custom-header-height,0px))] items-center justify-center text-caption text-text-2"
      >
        Loading API reference…
      </div>
    ),
  },
);
