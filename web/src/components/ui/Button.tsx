"use client";

// Button — design.md §8.2: kind gradient-primary / quiet / destructive /
// link · size md 44 / sm 36 · state default / pressed / disabled / loading.
// Figma master (39:66): radius/card corners, px 16/12, label 14/13 semibold,
// disabled 40%, loading = spinner-only. Pressed = Figma overlay tint +
// active scale (fast/standard, reduced-motion safe).
import { forwardRef, type ButtonHTMLAttributes } from "react";
import clsx from "clsx";
import { Spinner } from "./Spinner";

export type ButtonKind = "gradient-primary" | "quiet" | "destructive" | "link";
export type ButtonSize = "md" | "sm";

export interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  kind?: ButtonKind;
  size?: ButtonSize;
  loading?: boolean;
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  function Button(
    {
      kind = "gradient-primary",
      size = "md",
      loading = false,
      disabled,
      className,
      children,
      ...rest
    },
    ref,
  ) {
    const isDisabled = disabled || loading;
    return (
      <button
        ref={ref}
        type="button"
        disabled={isDisabled}
        aria-busy={loading || undefined}
        data-kind={kind}
        data-size={size}
        className={clsx(
          // whitespace-nowrap: pill/button labels never wrap — at narrow
          // widths a wrapped label overflows the fixed-height pill (the
          // 390px comparison-table CTAs were the live repro).
          "inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-card font-semibold",
          "transition-transform duration-120 ease-standard enabled:active:scale-[0.98]",
          "motion-reduce:transition-none motion-reduce:active:scale-100",
          "disabled:opacity-40 disabled:cursor-not-allowed",
          size === "md" ? "h-11 px-4 text-body" : "h-9 px-3 text-caption",
          kind === "gradient-primary" &&
            "bg-accent-gradient text-on-accent enabled:active:shadow-[inset_0_0_0_999px_rgba(0,0,0,0.16)]",
          kind === "quiet" &&
            "border border-border bg-bg-elev text-text enabled:active:bg-[rgba(128,128,128,0.18)]",
          kind === "destructive" &&
            "bg-error text-on-accent enabled:active:shadow-[inset_0_0_0_999px_rgba(0,0,0,0.16)]",
          kind === "link" &&
            "text-link underline-offset-2 hover:underline enabled:active:bg-[rgba(128,128,128,0.18)]",
          className,
        )}
        {...rest}
      >
        {loading ? (
          // Figma master: loading swaps the label for a spinner at fixed
          // width (spinner 18 md / 16 sm, on-accent on filled kinds).
          <Spinner
            size={size === "md" ? 18 : 16}
            kind={
              kind === "quiet" || kind === "link" ? "neutral" : "on-accent"
            }
          />
        ) : (
          children
        )}
      </button>
    );
  },
);
