"use client";

// WalkthroughStep — design.md §8.2b Home section kit: screenshot + 2 lines
// + step dots ×4 (as built 2026-07-18: the A4 walkthrough's four steps;
// active dot set per instance).
import clsx from "clsx";
import Image from "next/image";

export interface WalkthroughStepProps {
  /** Real screen thumbnail (exported Stage-4 frame, pages.md A4). */
  imageSrc: string;
  imageAlt: string;
  title: string;
  body: string;
  /** 0-based active dot of the four. */
  step: 0 | 1 | 2 | 3;
  className?: string;
}

export function WalkthroughStep({
  imageSrc,
  imageAlt,
  title,
  body,
  step,
  className,
}: WalkthroughStepProps) {
  return (
    <figure
      data-step={step}
      className={clsx("flex w-72 shrink-0 flex-col gap-4", className)}
    >
      <span className="relative block aspect-[9/16] w-full overflow-hidden rounded-card border border-border bg-border/30">
        <Image src={imageSrc} alt={imageAlt} fill sizes="288px" className="object-cover" />
      </span>
      <figcaption className="flex flex-col gap-1">
        <span className="text-body-lg font-semibold text-text">{title}</span>
        <span className="text-body text-text-2">{body}</span>
      </figcaption>
      <span data-testid="step-dots" className="flex gap-1.5">
        {[0, 1, 2, 3].map((i) => (
          <span
            key={i}
            data-active={i === step || undefined}
            className={clsx(
              "rounded-pill transition-all duration-120 ease-standard",
              i === step ? "h-1.5 w-4 bg-accent-gradient" : "size-1.5 bg-border",
            )}
          />
        ))}
      </span>
    </figure>
  );
}
