// EmptyState — design.md §3/§8.2: pattern-bg illustration + one-line + one
// CTA; contexts feed / vault / orders / explore / notifications (every list
// defines one). The Afrocentric pattern asset (§2) is still a design-prep
// item — until it ships, a low-opacity geometric line pattern stands in.
import clsx from "clsx";
import {
  Bell,
  Camera,
  Home,
  Package,
  Ruler,
  Search,
  type LucideIcon,
} from "lucide-react";
import { Button } from "./Button";

export type EmptyStateContext =
  | "feed"
  | "vault"
  | "orders"
  | "explore"
  | "notifications"
  | "camera-permission";

// Figma masters (54:459): icon, copy and CTA kind per context; primary CTAs
// paint the gradient, recovery/secondary ones stay quiet.
const CONTEXT: Record<
  EmptyStateContext,
  {
    icon: LucideIcon;
    line: string;
    cta: string;
    ctaKind: "gradient-primary" | "quiet";
    cta2?: string;
  }
> = {
  feed: {
    icon: Home,
    line: "Follow designers to fill your feed",
    cta: "Explore outfits",
    ctaKind: "gradient-primary",
  },
  vault: {
    icon: Ruler,
    line: "No measurements yet — take your first scan",
    cta: "Take measurement",
    ctaKind: "gradient-primary",
  },
  orders: {
    icon: Package,
    line: "No orders yet",
    cta: "Discover designers",
    ctaKind: "quiet",
  },
  explore: {
    icon: Search,
    line: "Nothing matches that search",
    cta: "Clear search",
    ctaKind: "quiet",
  },
  notifications: {
    icon: Bell,
    line: "You're all caught up",
    cta: "Back to feed",
    ctaKind: "quiet",
  },
  "camera-permission": {
    icon: Camera,
    line: "Camera access is off — enable it in Settings to measure automatically",
    cta: "Open Settings",
    ctaKind: "gradient-primary",
    cta2: "Enter manually instead",
  },
};

export interface EmptyStateProps {
  context: EmptyStateContext;
  /** Override the default one-liner/CTA when a screen specs its own copy. */
  line?: string;
  ctaLabel?: string;
  onCta?: () => void;
  /** camera-permission carries a quiet secondary CTA (98:1274). */
  onSecondaryCta?: () => void;
  className?: string;
}

export function EmptyState({
  context,
  line,
  ctaLabel,
  onCta,
  onSecondaryCta,
  className,
}: EmptyStateProps) {
  const spec = CONTEXT[context];
  const Icon = spec.icon;
  return (
    <div
      data-context={context}
      className={clsx(
        "relative flex flex-col items-center gap-4 overflow-hidden rounded-card px-8 py-12 text-center",
        className,
      )}
    >
      {/* pattern background — 4–6% opacity geometric lines (design.md §2) */}
      <svg
        aria-hidden="true"
        className="absolute inset-0 size-full text-text opacity-5"
      >
        <defs>
          <pattern
            id={`es-${context}`}
            width="24"
            height="24"
            patternUnits="userSpaceOnUse"
          >
            <path
              d="M0 24L24 0M-6 6L6 -6M18 30L30 18"
              stroke="currentColor"
              strokeWidth="1"
              fill="none"
            />
          </pattern>
        </defs>
        <rect width="100%" height="100%" fill={`url(#es-${context})`} />
      </svg>
      {/* Figma master: 88px dashed ring, 32px text-2 glyph, 13px text-2 line */}
      <span className="relative grid size-[88px] place-items-center rounded-pill border border-dashed border-border bg-bg-elev">
        <Icon size={32} className="text-text-2" />
      </span>
      <p className="relative max-w-80 text-caption text-text-2">
        {line ?? spec.line}
      </p>
      <Button
        kind={spec.ctaKind}
        size="sm"
        onClick={onCta}
        className="relative"
      >
        {ctaLabel ?? spec.cta}
      </Button>
      {spec.cta2 ? (
        <Button
          kind="quiet"
          size="sm"
          onClick={onSecondaryCta}
          className="relative"
        >
          {spec.cta2}
        </Button>
      ) : null}
    </div>
  );
}
