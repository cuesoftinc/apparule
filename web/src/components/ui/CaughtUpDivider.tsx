// CaughtUpDivider — design.md §8.2b (MI-6): "You're all caught up ✓" —
// check glyph + hairline pair, shown after 48h-old content.
import clsx from "clsx";
import { CheckCircle2 } from "lucide-react";

export function CaughtUpDivider({ className }: { className?: string }) {
  return (
    <div
      data-testid="caught-up"
      className={clsx("flex items-center gap-4 py-6", className)}
    >
      <span className="h-px flex-1 bg-border" />
      <span className="flex items-center gap-2 text-body text-text-2">
        <CheckCircle2 size={20} className="text-success" />
        You&apos;re all caught up
      </span>
      <span className="h-px flex-1 bg-border" />
    </div>
  );
}
