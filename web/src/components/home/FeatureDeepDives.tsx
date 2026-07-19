"use client";

// A4b Feature deep-dives — benefit-led split panels, alternating media/text
// (canvas 197:2/197:3, four panels): benefit headline · body · composed
// dashboard preview · quiet docs link. Panels fade-up on scroll-into-view
// (once, same rule as A3).
import clsx from "clsx";
import { Reveal } from "./Reveal";
import {
  DashExploreThumb,
  DashOrderDetailThumb,
  DashOrdersThumb,
  DashVaultThumb,
} from "./dash-thumbs";

// Verified GitBook target — per-feature sub-pages do not exist (404);
// every A4b quiet link deep-dives into the features page.
const DOCS_BASE = "https://cuesoft.gitbook.io/apparule/product/features";

const PANELS = [
  {
    headline: "Capture once, keep it fresh",
    body: "Two photos become a full set of body measurements in a private vault only you can see. Freshness tracking nudges you when it's time to retake — no stale numbers on new orders.",
    href: `${DOCS_BASE}`,
    thumb: <DashVaultThumb />,
    mediaFirst: false,
  },
  {
    headline: "Find designers near you",
    body: "Follow Lagos designers and browse real commissioned work, filtered by style, budget and turnaround. Proximity ranking surfaces ateliers close to you, so fittings and delivery stay easy.",
    href: `${DOCS_BASE}`,
    thumb: <DashExploreThumb />,
    mediaFirst: true,
  },
  {
    headline: "Escrow-protected commissions",
    body: "Pay when you accept a quote — funds are held in escrow, not sent ahead. Money releases when the outfit is delivered, and a dispute freezes payout until it's resolved.",
    href: `${DOCS_BASE}`,
    thumb: <DashOrdersThumb />,
    mediaFirst: false,
  },
  {
    headline: "Your measurements ride with every order",
    body: "Each request carries a locked snapshot of exactly the values you chose to share. Your designer sews to those numbers — no more guessing sizes over chat.",
    href: `${DOCS_BASE}`,
    thumb: <DashOrderDetailThumb />,
    mediaFirst: true,
  },
] as const;

export function FeatureDeepDives() {
  return (
    <section
      aria-labelledby="deep-dives-heading"
      className="mx-auto w-full max-w-[1128px] px-6 py-12"
    >
      <h2 id="deep-dives-heading" className="text-title-lg font-bold text-text">
        Built around your measurements
      </h2>
      <div className="mt-8 flex flex-col gap-12">
        {PANELS.map((panel) => (
          <Reveal key={panel.headline}>
            <div
              data-testid="deep-dive-panel"
              className={clsx(
                // canon deep-dive split: 528 + 24 gutter + 528 = 1080
                "flex flex-col items-start gap-8 md:items-center md:gap-6",
                panel.mediaFirst ? "md:flex-row-reverse" : "md:flex-row",
              )}
            >
              <div className="max-w-[528px] flex-1">
                <h3 className="text-title font-semibold text-text">
                  {panel.headline}
                </h3>
                <p className="mt-4 text-body text-text-2">{panel.body}</p>
                <a
                  href={panel.href}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="mt-6 inline-block text-body font-semibold text-link hover:underline"
                >
                  Read more →
                </a>
              </div>
              <div className="w-full max-w-[560px] shrink-0 md:w-[528px] md:max-w-none">
                {panel.thumb}
              </div>
            </div>
          </Reveal>
        ))}
      </div>
    </section>
  );
}
