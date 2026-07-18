"use client";

// OrderTimelineRow — design.md §8.2b: dot done / current (pulse 1→1.06→1) /
// pending / terminal-error · connector drawn / undrawn (MI-14: the dot
// draws its connector line over 400ms) · label + timestamp.
import clsx from "clsx";
import { format } from "date-fns";

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
      {/* Figma master (89:1075): label with the timestamp stacked beneath;
          pending rows read "Pending" */}
      <div className="flex flex-1 flex-col gap-0.5 pb-6">
        <span
          className={clsx(
            "text-body",
            dot === "pending" ? "text-text-2" : "font-semibold text-text",
          )}
        >
          {label}
        </span>
        {timestamp ? (
          // suppressHydrationWarning: render-time timestamps may differ
          // between server and client by design
          <time
            dateTime={timestamp}
            suppressHydrationWarning
            className="tnum text-micro text-text-2"
          >
            {format(new Date(timestamp), "MMM d, HH:mm")}
          </time>
        ) : dot === "pending" ? (
          <span className="text-micro text-text-2">Pending</span>
        ) : null}
      </div>
    </div>
  );
}
