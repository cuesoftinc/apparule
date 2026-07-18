"use client";

// StatusPill — design.md §8.2: the 10 order states + freshness
// (fresh/aging/stale). [Decided 2026-07-16] order-state → token mapping:
// quoted/shipped → link · paid/delivered → success · in_progress/refunded →
// warn · declined/disputed → error · requested/cancelled → text-2.
// MI-14: status changes pulse once (scale 1→1.06→1) + color crossfade.
import { useEffect, useRef, useState } from "react";
import clsx from "clsx";
import type { OrderStatus } from "@/models";
import type { Freshness } from "@/models";

export type StatusPillValue = OrderStatus | Freshness;

const TOKEN_CLASS: Record<StatusPillValue, string> = {
  quoted: "text-link border-link/40 bg-link/10",
  shipped: "text-link border-link/40 bg-link/10",
  paid: "text-success border-success/40 bg-success/10",
  delivered: "text-success border-success/40 bg-success/10",
  in_progress: "text-warn border-warn/40 bg-warn/10",
  refunded: "text-warn border-warn/40 bg-warn/10",
  declined: "text-error border-error/40 bg-error/10",
  disputed: "text-error border-error/40 bg-error/10",
  requested: "text-text-2 border-border bg-bg-elev",
  cancelled: "text-text-2 border-border bg-bg-elev",
  fresh: "text-success border-success/40 bg-success/10",
  aging: "text-warn border-warn/40 bg-warn/10",
  stale: "text-text-2 border-border bg-bg-elev",
};

export interface StatusPillProps {
  status: StatusPillValue;
  className?: string;
}

export function StatusPill({ status, className }: StatusPillProps) {
  const [pulse, setPulse] = useState(false);
  const previous = useRef(status);

  // MI-14: pulse once when the status value changes.
  useEffect(() => {
    if (previous.current !== status) {
      previous.current = status;
      setPulse(true);
      const t = setTimeout(() => setPulse(false), 300);
      return () => clearTimeout(t);
    }
  }, [status]);

  return (
    <span
      data-status={status}
      className={clsx(
        "inline-flex h-6 items-center rounded-pill border px-3 text-caption font-semibold",
        "transition-colors duration-200 ease-standard motion-reduce:transition-none",
        TOKEN_CLASS[status],
        pulse &&
          "animate-[status-pulse_300ms_var(--ap-ease-standard)] motion-reduce:animate-none",
        className,
      )}
    >
      {status.replace(/_/g, " ")}
    </span>
  );
}
