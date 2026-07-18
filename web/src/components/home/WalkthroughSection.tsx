"use client";

// A4 Product walkthrough — 4 steps Capture → Vault → Discover → Commission
// (canvas 186:49/186:50): WalkthroughStep instances with composed mini
// previews in the screenshot slots. Step dots + keyboard arrows; the
// scroll-jacked panel is adapted to a snap-scrolling rail on desktop and a
// vertical stack on mobile (pages.md: scroll-jack disabled on mobile).
// First engagement fires `demo_start`.
import { useRef } from "react";
import { WalkthroughStep } from "@/components/ui/WalkthroughStep";
import { track } from "@/controllers/analytics";
import {
  CaptureThumb,
  ExploreThumb,
  OrdersThumb,
  VaultThumb,
} from "./mobile-thumbs";

const STEPS = [
  {
    title: "Capture",
    body: "Two photos — your measurements, automatically",
    thumb: <CaptureThumb />,
  },
  {
    title: "Vault",
    body: "Private history, freshness-tracked",
    thumb: <VaultThumb />,
  },
  {
    title: "Discover",
    body: "Follow designers, find your style",
    thumb: <ExploreThumb />,
  },
  {
    title: "Commission",
    body: "Request with your measurements attached",
    thumb: <OrdersThumb />,
  },
] as const;

export function WalkthroughSection() {
  const railRef = useRef<HTMLDivElement>(null);
  const engagedRef = useRef(false);

  function engage() {
    if (engagedRef.current) return;
    engagedRef.current = true;
    track("demo_start", { section: "walkthrough" });
  }

  function onKeyDown(event: React.KeyboardEvent<HTMLDivElement>) {
    if (event.key !== "ArrowRight" && event.key !== "ArrowLeft") return;
    event.preventDefault();
    engage();
    const rail = railRef.current;
    if (!rail) return;
    const stepWidth = rail.scrollWidth / STEPS.length;
    rail.scrollBy({
      left: event.key === "ArrowRight" ? stepWidth : -stepWidth,
      behavior: "smooth",
    });
  }

  return (
    <section
      aria-labelledby="walkthrough-heading"
      className="mx-auto w-full max-w-[1080px] px-6 py-12"
    >
      <h2 id="walkthrough-heading" className="text-title-lg font-bold text-text">
        How it works
      </h2>
      <div
        ref={railRef}
        role="group"
        aria-label="Product walkthrough — use arrow keys to move between steps"
        tabIndex={0}
        onKeyDown={onKeyDown}
        onScroll={engage}
        data-testid="walkthrough-rail"
        // xl:-mr-40 — the Figma walkthrough row runs 1192 wide, extending
        // right past the 1080 heading grid; below xl the rail snap-scrolls
        className="mt-6 flex snap-x snap-mandatory flex-col gap-8 overflow-x-auto pb-2 md:flex-row md:gap-6 xl:-mr-40"
      >
        {STEPS.map((step, i) => (
          <WalkthroughStep
            key={step.title}
            title={step.title}
            body={step.body}
            thumb={step.thumb}
            step={i as 0 | 1 | 2 | 3}
            className="snap-start"
          />
        ))}
      </div>
    </section>
  );
}
