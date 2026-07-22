"use client";

// AppBar — design.md §8.2b: kind root (title/logo + action slot) / sub
// (chevron-left + title + trailing action) / over-media (transparent).
// Row alignment (M-9, ratified 2026-07-22): sub/over-media titles center on
// the FULL bar width — an absolute, full-width, center-aligned text layer
// over the bar, never an in-flow element between the slots (an in-flow
// title grows into a hidden trailing slot and skews off-center — with a
// back-only bar the old layout sat ~22px right of true center).
// Leading/trailing slots stay in-flow at the edges; the title's horizontal
// padding reserves the widest slot. `root` (left wordmark) is exempt.
import type { ReactNode } from "react";
import clsx from "clsx";
import { ChevronLeft } from "lucide-react";

export type AppBarKind = "root" | "sub" | "over-media";

export interface AppBarProps {
  kind?: AppBarKind;
  title?: string;
  /** sub / over-media: chevron-left back action. */
  onBack?: () => void;
  /** Trailing action slot. */
  trailing?: ReactNode;
  className?: string;
}

export function AppBar({
  kind = "root",
  title,
  onBack,
  trailing,
  className,
}: AppBarProps) {
  return (
    <header
      data-kind={kind}
      className={clsx(
        "relative flex h-14 items-center gap-2 px-4",
        kind === "over-media"
          ? // On-media capture/photo chrome — raw white on a scrim is the
            // documented token exception (web-implementation.md §3 note).
            "bg-gradient-to-b from-black/40 to-transparent text-white"
          : "border-b border-border bg-bg text-text",
        className,
      )}
    >
      {kind !== "root" && onBack ? (
        <button
          type="button"
          aria-label="Back"
          onClick={onBack}
          className={clsx(
            "-ml-2 grid size-11 place-items-center rounded-pill",
            "transition-colors duration-120 ease-standard motion-reduce:transition-none",
            kind === "over-media" ? "hover:bg-white/10" : "hover:bg-border/30",
          )}
        >
          <ChevronLeft size={24} />
        </button>
      ) : null}
      {kind === "root" ? (
        // Figma master (85:994): root paints the gradient wordmark, left.
        <div className="min-w-0 flex-1 truncate bg-accent-gradient bg-clip-text text-title font-semibold text-transparent">
          {title}
        </div>
      ) : (
        // M-9: the 16px title centers on the full bar width — an absolute
        // layer over the bar (not the between-actions flex remainder).
        // px-14 reserves the widest action slot (44px + bar padding);
        // pointer-events-none keeps the in-flow slots clickable beneath.
        <div
          data-testid="appbar-title"
          className="pointer-events-none absolute inset-x-0 top-0 flex h-full items-center justify-center px-14"
        >
          <span className="truncate text-body-lg font-semibold">{title}</span>
        </div>
      )}
      {trailing ? (
        <div className="ml-auto flex shrink-0 items-center gap-1">
          {trailing}
        </div>
      ) : null}
    </header>
  );
}
