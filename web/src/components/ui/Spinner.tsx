"use client";

// Spinner — design.md §8.2b: size 20 inline / 28 refresh · kind: gradient
// (pull-to-refresh, MI-5) / neutral. SVG arc; gradient kind strokes the
// accent gradient (two stops bound to accent-start/accent-end, §7).
import clsx from "clsx";
import { useId } from "react";

export interface SpinnerProps {
  size?: 20 | 28;
  kind?: "gradient" | "neutral";
  /** MI-5: pull-to-refresh grows with pull distance (0–1). */
  progress?: number;
  className?: string;
  "aria-label"?: string;
}

export function Spinner({
  size = 20,
  kind = "neutral",
  progress,
  className,
  "aria-label": ariaLabel = "Loading",
}: SpinnerProps) {
  const gradientId = useId();
  const stroke = 2.5;
  const r = (size - stroke) / 2;
  const c = size / 2;
  const circumference = 2 * Math.PI * r;
  const scale = progress !== undefined ? Math.min(Math.max(progress, 0), 1) : 1;

  return (
    <svg
      width={size}
      height={size}
      viewBox={`0 0 ${size} ${size}`}
      role="status"
      aria-label={ariaLabel}
      style={progress !== undefined ? { transform: `scale(${scale})` } : undefined}
      className={clsx(
        progress === undefined && "animate-spin motion-reduce:animate-none",
        className,
      )}
    >
      {kind === "gradient" ? (
        <defs>
          <linearGradient id={gradientId} x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="var(--ap-accent-start)" />
            <stop offset="100%" stopColor="var(--ap-accent-end)" />
          </linearGradient>
        </defs>
      ) : null}
      <circle
        cx={c}
        cy={c}
        r={r}
        fill="none"
        stroke={kind === "gradient" ? `url(#${gradientId})` : "var(--ap-text-2)"}
        strokeWidth={stroke}
        strokeLinecap="round"
        strokeDasharray={circumference}
        strokeDashoffset={circumference * 0.3}
      />
    </svg>
  );
}
