"use client";

// CaptureOverlay — design.md §8.2b: guide searching (silhouette pulses
// gently) / aligned (guide turns success) / countdown / qc-hint (chip slot)
// — dashed silhouette vector over the camera viewport (MI-12).
// On-media capture UI: raw white over the camera feed is the documented
// token exception (web-implementation.md §3 note).
import type { ReactNode } from "react";
import clsx from "clsx";
import { CountdownRing } from "./CountdownRing";
import { QCHintChip, type QcFailCode } from "./QCHintChip";

export type CaptureGuideState = "searching" | "aligned" | "countdown" | "qc-hint";

export interface CaptureOverlayProps {
  guide: CaptureGuideState;
  /** countdown guide: the current tick. */
  countdownValue?: 1 | 2 | 3;
  /** qc-hint guide: the fail code to surface. */
  qcCode?: QcFailCode;
  /** The camera viewport (video / img); fills the frame behind the guide. */
  children?: ReactNode;
  className?: string;
}

export function CaptureOverlay({
  guide,
  countdownValue = 3,
  qcCode,
  children,
  className,
}: CaptureOverlayProps) {
  return (
    <div
      data-guide={guide}
      className={clsx(
        "relative aspect-[3/4] w-full overflow-hidden rounded-card bg-black",
        className,
      )}
    >
      <div className="absolute inset-0">{children}</div>

      {/* Dashed standing-silhouette guide (head → shoulders → arms-out →
          ankles), centered over the viewport. */}
      <svg
        data-testid="silhouette"
        viewBox="0 0 200 300"
        aria-hidden="true"
        className={clsx(
          "absolute inset-0 m-auto h-[85%]",
          guide === "searching" &&
            "animate-[silhouette-pulse_2s_ease-in-out_infinite] motion-reduce:animate-none motion-reduce:opacity-70",
          guide !== "searching" && "opacity-80",
        )}
      >
        <g
          fill="none"
          stroke={guide === "aligned" ? "var(--ap-success)" : "white"}
          strokeWidth={2.5}
          strokeDasharray="6 6"
          strokeLinecap="round"
          strokeLinejoin="round"
        >
          {/* head */}
          <circle cx={100} cy={38} r={22} />
          {/* torso + arms slightly out (capture-qc.md arms clearance) */}
          <path d="M100 60 C 78 64 68 74 66 92 L 46 148 M100 60 C 122 64 132 74 134 92 L 154 148 M72 88 C 72 120 76 142 80 160 L 76 232 L 72 284 M128 88 C 128 120 124 142 120 160 L 124 232 L 128 284 M80 160 C 92 168 108 168 120 160" />
        </g>
      </svg>

      {guide === "countdown" ? (
        <div className="absolute inset-0 grid place-items-center">
          <CountdownRing value={countdownValue} />
        </div>
      ) : null}

      {guide === "qc-hint" && qcCode ? (
        <div className="absolute inset-x-0 bottom-6 flex justify-center px-4">
          <QCHintChip code={qcCode} />
        </div>
      ) : null}
    </div>
  );
}
