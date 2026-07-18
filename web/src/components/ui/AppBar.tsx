"use client";

// AppBar — design.md §8.2b: kind root (title/logo + action slot) / sub
// (chevron-left + title + trailing action) / over-media (transparent).
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
        "flex h-14 items-center gap-2 px-4",
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
      <div
        className={clsx(
          "min-w-0 flex-1 truncate font-semibold",
          // Figma master (85:994): root paints the gradient wordmark;
          // sub/over-media center a 16px title between the actions.
          kind === "root"
            ? "bg-accent-gradient bg-clip-text text-title text-transparent"
            : "text-center text-body-lg",
        )}
      >
        {title}
      </div>
      {trailing ? (
        <div className="flex shrink-0 items-center gap-1">{trailing}</div>
      ) : null}
    </header>
  );
}
