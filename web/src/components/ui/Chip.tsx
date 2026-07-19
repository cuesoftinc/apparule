"use client";

// Chip — design.md §8.2 (Pill/Chip atom): kind default / selected /
// removable. Removable renders a trailing ✕ affordance (filter chips, tags).
import { type ButtonHTMLAttributes } from "react";
import clsx from "clsx";
import { X } from "lucide-react";

export type ChipKind = "default" | "selected" | "removable";

export interface ChipProps
  extends Omit<ButtonHTMLAttributes<HTMLButtonElement>, "onSelect"> {
  kind?: ChipKind;
  label: string;
  /** Removable chips call this from the ✕ affordance. */
  onRemove?: () => void;
}

// Figma master (41:19): 13px semibold label; selected = solid text-token
// fill (reads as active filter, not an action). whitespace-nowrap: a chip
// is a fixed-height pill — wrapped labels clip out of it in constrained
// rows (walkthrough mini-screens).
const PILL_CLASSES = [
  "inline-flex h-8 items-center gap-1.5 whitespace-nowrap rounded-pill border px-3 text-caption font-semibold",
  "transition-colors duration-120 ease-standard motion-reduce:transition-none",
];

export function Chip({
  kind = "default",
  label,
  onRemove,
  className,
  disabled,
  ...rest
}: ChipProps) {
  if (kind === "removable") {
    // Removable = two REAL buttons in a pill container — a button may not
    // own interactive descendants, and the ✕ must be keyboard-reachable
    // (semantic canon; formerly a tabIndex=-1 span[role=button] inside the
    // chip button). `disabled` gates BOTH buttons — the ✕ must not stay
    // clickable (mouse or keyboard) when the chip itself is disabled.
    return (
      <span
        data-kind="removable"
        className={clsx(PILL_CLASSES, "border-border bg-bg-elev text-text", className)}
      >
        <button
          type="button"
          data-kind={kind}
          disabled={disabled}
          className="inline-flex items-center whitespace-nowrap disabled:cursor-not-allowed disabled:opacity-40"
          {...rest}
        >
          {label}
        </button>
        <button
          type="button"
          aria-label={`Remove ${label}`}
          disabled={disabled}
          onClick={(e) => {
            e.stopPropagation();
            if (disabled) return;
            onRemove?.();
          }}
          className="-mr-1 grid size-4 place-items-center rounded-pill text-text-2 hover:text-text disabled:cursor-not-allowed disabled:opacity-40"
        >
          <X size={14} strokeWidth={2.5} />
        </button>
      </span>
    );
  }
  return (
    <button
      type="button"
      data-kind={kind}
      aria-pressed={kind === "selected" || undefined}
      disabled={disabled}
      className={clsx(
        PILL_CLASSES,
        kind === "selected"
          ? "border-transparent bg-text text-bg"
          : "border-border bg-bg-elev text-text",
        "disabled:cursor-not-allowed disabled:opacity-40",
        className,
      )}
      {...rest}
    >
      <span>{label}</span>
    </button>
  );
}
