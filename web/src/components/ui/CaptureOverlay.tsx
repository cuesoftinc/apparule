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
        // Figma master (63:701): 9:16 viewport, 40% scrim, corner marks,
        // top instruction line.
        "relative aspect-[9/16] w-full overflow-hidden rounded-card bg-black",
        className,
      )}
    >
      <div className="absolute inset-0">{children}</div>
      <div className="absolute inset-0 bg-black/40" aria-hidden />

      {/* viewfinder corner marks */}
      <svg
        data-testid="corner-marks"
        viewBox="0 0 360 640"
        aria-hidden="true"
        className="absolute inset-0 size-full"
        preserveAspectRatio="none"
      >
        <g fill="none" stroke="white" strokeWidth={3} strokeLinecap="round">
          <path d="M24 56 V32 H48 M312 32 H336 V56 M336 584 V608 H312 M48 608 H24 V584" />
        </g>
      </svg>

      {/* instruction line — 16px semibold white, top-centered */}
      <p className="absolute inset-x-4 top-[9%] text-center text-body-lg font-semibold text-white">
        {guide === "aligned" ? "Perfect — hold still" : "Stand inside the outline"}
      </p>

      {/* Standing-silhouette guide (head → shoulders → arms-out → ankles),
          centered over the viewport; dashed while searching, solid success
          stroke when aligned (MI-12). */}
      <svg
        data-testid="silhouette"
        viewBox="0 0 200 300"
        aria-hidden="true"
        className={clsx(
          "absolute inset-0 m-auto h-[70%]",
          guide === "searching" &&
            "animate-[silhouette-pulse_2s_ease-in-out_infinite] motion-reduce:animate-none motion-reduce:opacity-70",
          guide !== "searching" && "opacity-80",
        )}
      >
        <g
          fill="none"
          stroke={guide === "aligned" ? "var(--ap-success)" : "white"}
          strokeWidth={2.5}
          strokeDasharray={guide === "aligned" ? undefined : "6 6"}
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
