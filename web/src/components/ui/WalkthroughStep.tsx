"use client";

// WalkthroughStep — design.md §8.2b Home section kit: screenshot slot +
// 2 lines + step dots ×4 (as built 2026-07-18: the A4 walkthrough's four
// steps; the active dot is set per instance — accent-start marks the
// current step). Figma master 142:3686: 280 wide, 280×180 slot on bg-elev.
// The slot takes either a real screen thumbnail (`imageSrc`) or a composed
// mini preview of real components (`thumb`) — the W2 adaptation until the
// Stage-4 frame exports land (pages.md A4 note).
import clsx from "clsx";
import Image from "next/image";
import type { ReactNode } from "react";

export interface WalkthroughStepProps {
  /** Real screen thumbnail (exported Stage-4 frame, pages.md A4). */
  imageSrc?: string;
  imageAlt?: string;
  /** Composed mini preview (real component instances) — fills the slot. */
  thumb?: ReactNode;
  title: string;
  body: string;
  /** 0-based active dot of the four. */
  step: 0 | 1 | 2 | 3;
  className?: string;
}

export function WalkthroughStep({
  imageSrc,
  imageAlt = "",
  thumb,
  title,
  body,
  step,
  className,
}: WalkthroughStepProps) {
  return (
    <figure
      data-step={step}
      className={clsx("flex w-70 shrink-0 flex-col gap-4", className)}
    >
      <span className="relative block h-45 w-full overflow-hidden rounded-card border border-border bg-bg-elev">
        {thumb ??
          (imageSrc ? (
            <Image src={imageSrc} alt={imageAlt} fill sizes="280px" className="object-cover" />
          ) : null)}
      </span>
      <figcaption className="flex flex-col gap-1">
        <span className="text-body-lg font-semibold text-text">{title}</span>
        <span className="text-body text-text-2">{body}</span>
      </figcaption>
      <span data-testid="step-dots" className="flex gap-2">
        {[0, 1, 2, 3].map((i) => (
          <span
            key={i}
            data-active={i === step || undefined}
            className={clsx(
              // Figma master: 8px dots; the active one binds accent-start
              "size-2 rounded-pill transition-colors duration-120 ease-standard",
              i === step ? "bg-accent-start" : "bg-border",
            )}
          />
        ))}
      </span>
    </figure>
  );
}
