"use client";

// OrderTimelineRow — design.md §8.2b: dot done / current (pulse 1→1.06→1) /
// pending / terminal-error · connector drawn / undrawn (MI-14: the dot
// draws its connector line over 400ms) · label + timestamp.
import clsx from "clsx";
import { formatAgo } from "@/lib/format";

export type TimelineDot = "done" | "current" | "pending" | "terminal-error";

export interface OrderTimelineRowProps {
  dot: TimelineDot;
  /** Connector below the dot: drawn / undrawn; last row renders none. */
  connector?: "drawn" | "undrawn" | "none";
  label: string;
  timestamp?: string | null;
  className?: string;
}

export function OrderTimelineRow({
  dot,
  connector = "none",
  label,
  timestamp,
  className,
}: OrderTimelineRowProps) {
  return (
    <div
      data-dot={dot}
      data-connector={connector}
      className={clsx("flex gap-3", className)}
    >
      <div className="flex flex-col items-center">
        <span
          className={clsx(
            "mt-0.5 grid size-4 shrink-0 place-items-center rounded-pill",
            dot === "done" && "bg-success",
            dot === "current" &&
              "bg-accent-gradient animate-[status-pulse_1.2s_var(--ap-ease-standard)_infinite] motion-reduce:animate-none",
            dot === "pending" && "border-2 border-border bg-bg",
            dot === "terminal-error" && "bg-error",
          )}
        />
        {connector !== "none" ? (
          <span
            data-testid="connector"
            className={clsx(
              "w-0.5 flex-1 origin-top",
              connector === "drawn"
                ? "bg-border animate-[draw-line_400ms_var(--ap-ease-standard)] motion-reduce:animate-none"
                : "bg-border/40",
            )}
          />
        ) : null}
      </div>
      <div className="flex flex-1 items-baseline justify-between gap-3 pb-6">
        <span
          className={clsx(
            "text-body",
            dot === "pending" ? "text-text-2" : "font-semibold text-text",
            dot === "terminal-error" && "text-error",
          )}
        >
          {label}
        </span>
        {timestamp ? (
          <time dateTime={timestamp} className="shrink-0 text-caption text-text-2">
            {formatAgo(timestamp)}
          </time>
        ) : null}
      </div>
    </div>
  );
}
