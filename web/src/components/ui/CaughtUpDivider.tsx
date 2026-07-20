// CaughtUpDivider — design.md §8.2b (MI-6): "You're all caught up ✓" —
// check glyph + hairline pair, shown after 48h-old content.
import clsx from "clsx";
import { Check } from "lucide-react";

export function CaughtUpDivider({ className }: { className?: string }) {
  return (
    <div
      data-testid="caught-up"
      className={clsx("flex items-center gap-3 py-6", className)}
    >
      {/* Figma master (96:1214): 24px OUTLINED accent ring with a 12px
          check inside (not a filled disc), 13px semibold text-2 label. */}
      <span className="h-px flex-1 bg-border" />
      <span className="flex items-center gap-2 text-caption font-semibold text-text-2">
        <span
          aria-hidden
          className="grid size-6 place-items-center rounded-pill border-[1.5px] border-accent-start"
        >
          <Check size={12} className="text-accent-start" />
        </span>
        You&apos;re all caught up
      </span>
      <span className="h-px flex-1 bg-border" />
    </div>
  );
}
