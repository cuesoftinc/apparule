// Skeleton — design.md §8.2 (as built): kind line / avatar / media / card
// (§3 anatomy). MI-19: 1.2s linear shimmer, 8% white overlay; respects
// prefers-reduced-motion (static block).
import clsx from "clsx";

export type SkeletonKind = "line" | "avatar" | "media" | "card";

export interface SkeletonProps {
  kind?: SkeletonKind;
  className?: string;
}

function Shimmer({ className, kind }: { className?: string; kind: string }) {
  return (
    <div
      data-kind={kind}
      aria-hidden="true"
      className={clsx(
        "relative overflow-hidden bg-border/50",
        "after:absolute after:inset-0 after:-translate-x-full after:bg-gradient-to-r after:from-transparent after:via-white/8 after:to-transparent",
        "after:animate-[shimmer_1.2s_linear_infinite] motion-reduce:after:animate-none",
        className,
      )}
    />
  );
}

export function Skeleton({ kind = "line", className }: SkeletonProps) {
  if (kind === "line") {
    return <Shimmer kind={kind} className={clsx("h-4 w-full rounded-card", className)} />;
  }
  if (kind === "avatar") {
    return <Shimmer kind={kind} className={clsx("size-11 rounded-pill", className)} />;
  }
  if (kind === "media") {
    return <Shimmer kind={kind} className={clsx("aspect-square w-full", className)} />;
  }
  // card: feed anatomy — header line + square media + action row (§3)
  return (
    <div data-kind="card" aria-hidden="true" className={clsx("flex flex-col gap-3", className)}>
      <div className="flex items-center gap-3 px-4 pt-3">
        <Shimmer kind="avatar" className="size-8 shrink-0 rounded-pill" />
        <Shimmer kind="line" className="h-3 w-32 rounded-card" />
      </div>
      <Shimmer kind="media" className="aspect-square w-full" />
      <div className="flex items-center gap-4 px-4 pb-3">
        <Shimmer kind="line" className="h-6 w-6 rounded-card" />
        <Shimmer kind="line" className="h-6 w-6 rounded-card" />
        <Shimmer kind="line" className="h-6 w-6 rounded-card" />
      </div>
    </div>
  );
}
