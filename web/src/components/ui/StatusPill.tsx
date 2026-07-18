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

// Figma master (47:135): borderless pills — a 14% tint of the status token
// behind a 12px semibold label. fresh strokes the accent gradient.
const TOKEN_CLASS: Record<StatusPillValue, string> = {
  quoted: "text-link bg-link/14",
  shipped: "text-link bg-link/14",
  paid: "text-success bg-success/14",
  delivered: "text-success bg-success/14",
  in_progress: "text-warn bg-warn/14",
  refunded: "text-warn bg-warn/14",
  declined: "text-error bg-error/14",
  disputed: "text-error bg-error/14",
  requested: "text-text-2 bg-text-2/14",
  cancelled: "text-text-2 bg-text-2/14",
  fresh:
    "bg-[linear-gradient(135deg,color-mix(in_srgb,var(--ap-accent-start)_14%,transparent),color-mix(in_srgb,var(--ap-accent-end)_14%,transparent))]",
  aging: "text-warn bg-warn/14",
  stale: "text-text-2 bg-text-2/14",
};

export interface StatusPillProps {
  status: StatusPillValue;
  className?: string;
}

/** Figma masters label pills in sentence case ("In progress"). */
function label(status: StatusPillValue): string {
  const text = status.replace(/_/g, " ");
  return text.charAt(0).toUpperCase() + text.slice(1);
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
        "inline-flex h-6 items-center rounded-pill px-2 text-micro font-semibold",
        "transition-colors duration-200 ease-standard motion-reduce:transition-none",
        TOKEN_CLASS[status],
        pulse &&
          "animate-[status-pulse_300ms_var(--ap-ease-standard)] motion-reduce:animate-none",
        className,
      )}
    >
      {status === "fresh" ? (
        <span className="bg-accent-gradient bg-clip-text text-transparent">
          {label(status)}
        </span>
      ) : (
        label(status)
      )}
    </span>
  );
}
