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

export function Chip({
  kind = "default",
  label,
  onRemove,
  className,
  ...rest
}: ChipProps) {
  return (
    <button
      type="button"
      data-kind={kind}
      aria-pressed={kind === "selected" || undefined}
      className={clsx(
        "inline-flex h-8 items-center gap-1 rounded-pill border px-3 text-body",
        "transition-colors duration-120 ease-standard motion-reduce:transition-none",
        kind === "selected"
          ? "border-transparent bg-accent-gradient font-semibold text-on-accent"
          : "border-border bg-bg-elev text-text",
        className,
      )}
      {...rest}
    >
      <span>{label}</span>
      {kind === "removable" ? (
        <span
          role="button"
          aria-label={`Remove ${label}`}
          tabIndex={-1}
          onClick={(e) => {
            e.stopPropagation();
            onRemove?.();
          }}
          className="-mr-1 grid size-4 place-items-center rounded-pill text-text-2 hover:text-text"
        >
          <X size={12} strokeWidth={2.5} />
        </span>
      ) : null}
    </button>
  );
}
