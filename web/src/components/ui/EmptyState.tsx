// EmptyState — design.md §3/§8.2: pattern-bg illustration + one-line + one
// CTA; contexts feed / vault / orders / explore / notifications (every list
// defines one). The Afrocentric pattern asset (§2) is still a design-prep
// item — until it ships, a low-opacity geometric line pattern stands in.
import clsx from "clsx";
import {
  Bell,
  Compass,
  Package,
  Ruler,
  Users,
  type LucideIcon,
} from "lucide-react";
import { Button } from "./Button";

export type EmptyStateContext =
  | "feed"
  | "vault"
  | "orders"
  | "explore"
  | "notifications";

const CONTEXT: Record<EmptyStateContext, { icon: LucideIcon; line: string; cta: string }> = {
  feed: {
    icon: Users,
    line: "Follow designers to fill your feed",
    cta: "Explore designers",
  },
  vault: {
    icon: Ruler,
    line: "No measurements yet — take your first capture",
    cta: "Measure now",
  },
  orders: {
    icon: Package,
    line: "No orders yet — request an outfit you love",
    cta: "Explore outfits",
  },
  explore: {
    icon: Compass,
    line: "Nothing matches that search",
    cta: "Clear filters",
  },
  notifications: {
    icon: Bell,
    line: "You're all caught up — nothing new",
    cta: "Back to feed",
  },
};

export interface EmptyStateProps {
  context: EmptyStateContext;
  /** Override the default one-liner/CTA when a screen specs its own copy. */
  line?: string;
  ctaLabel?: string;
  onCta?: () => void;
  className?: string;
}

export function EmptyState({
  context,
  line,
  ctaLabel,
  onCta,
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
          <pattern id={`es-${context}`} width="24" height="24" patternUnits="userSpaceOnUse">
            <path d="M0 24L24 0M-6 6L6 -6M18 30L30 18" stroke="currentColor" strokeWidth="1" fill="none" />
          </pattern>
        </defs>
        <rect width="100%" height="100%" fill={`url(#es-${context})`} />
      </svg>
      <span className="relative grid size-16 place-items-center rounded-pill border border-border bg-bg-elev">
        <Icon size={28} className="text-text-2" />
      </span>
      <p className="relative text-body-lg text-text">{line ?? spec.line}</p>
      <Button kind="gradient-primary" size="sm" onClick={onCta} className="relative">
        {ctaLabel ?? spec.cta}
      </Button>
    </div>
  );
}
