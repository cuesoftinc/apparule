"use client";

// ProcessingConstellation — design.md §8.2b: state processing (landmark
// constellation animates over the photo — the "AI is working" moment,
// MI-12; also the SMPL demo asset) / success / failed.
// On-media capture UI: raw white over the photo is the documented token
// exception (web-implementation.md §3 note).
import clsx from "clsx";
import { Check, X } from "lucide-react";

export type ProcessingState = "processing" | "success" | "failed";

export interface ProcessingConstellationProps {
  state: ProcessingState;
  /** The captured photo the constellation draws over. */
  imageSrc?: string;
  imageAlt?: string;
  className?: string;
}

// Simplified MediaPipe-pose landmark set (nose, shoulders, elbows, wrists,
// hips, knees, ankles) in the 200×300 guide space.
const LANDMARKS: [number, number][] = [
  [100, 40], // nose
  [72, 88],
  [128, 88], // shoulders
  [56, 130],
  [144, 130], // elbows
  [48, 170],
  [152, 170], // wrists
  [82, 164],
  [118, 164], // hips
  [78, 222],
  [122, 222], // knees
  [74, 280],
  [126, 280], // ankles
];

const SEGMENTS: [number, number][] = [
  [0, 1],
  [0, 2],
  [1, 2], // head → shoulders
  [1, 3],
  [3, 5],
  [2, 4],
  [4, 6], // arms
  [1, 7],
  [2, 8],
  [7, 8], // torso
  [7, 9],
  [9, 11],
  [8, 10],
  [10, 12], // legs
];

export function ProcessingConstellation({
  state,
  imageSrc,
  imageAlt = "Captured photo",
  className,
}: ProcessingConstellationProps) {
  return (
    <div data-state={state} className={clsx("flex flex-col gap-2", className)}>
      <div className="relative aspect-[3/4] w-full overflow-hidden rounded-card bg-black">
        {imageSrc ? (
          // eslint-disable-next-line @next/next/no-img-element -- mock/demo asset, unoptimized by design
          <img
            src={imageSrc}
            alt={imageAlt}
            className="absolute inset-0 size-full object-cover opacity-60"
          />
        ) : null}

        {/* Figma master (64:748): the landmark constellation strokes the
            accent in every state; the status line sits below the photo. */}
        <svg
          data-testid="constellation"
          viewBox="0 0 200 300"
          aria-hidden="true"
          className="absolute inset-0 m-auto h-[85%]"
        >
          <g
            stroke="var(--ap-accent-start)"
            strokeOpacity={0.6}
            strokeWidth={1.5}
          >
            {SEGMENTS.map(([a, b]) => (
              <line
                key={`${a}-${b}`}
                x1={LANDMARKS[a][0]}
                y1={LANDMARKS[a][1]}
                x2={LANDMARKS[b][0]}
                y2={LANDMARKS[b][1]}
              />
            ))}
          </g>
          {LANDMARKS.map(([x, y], i) => (
            <circle
              key={`${x}-${y}`}
              data-testid="landmark"
              cx={x}
              cy={y}
              r={4}
              fill="var(--ap-accent-start)"
              style={
                state === "processing"
                  ? { animationDelay: `${i * 90}ms` }
                  : undefined
              }
              className={clsx(
                state === "processing" &&
                  "animate-[landmark-pulse_1.2s_ease-in-out_infinite] motion-reduce:animate-none",
              )}
            />
          ))}
        </svg>
      </div>

      <div
        role="status"
        className={clsx(
          "flex items-center justify-center gap-1 text-caption",
          state === "processing" && "text-text-2",
          state === "success" && "text-success",
          state === "failed" && "text-error",
        )}
      >
        {state === "success" ? <Check size={14} aria-hidden="true" /> : null}
        {state === "failed" ? <X size={14} aria-hidden="true" /> : null}
        <span>
          {state === "processing"
            ? "Measuring…"
            : state === "success"
              ? "Done"
              : "Couldn't measure — retake"}
        </span>
      </div>
    </div>
  );
}
