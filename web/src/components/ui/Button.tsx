"use client";

// Button — design.md §8.2: kind gradient-primary / quiet / destructive /
// link · size md 44 / sm 36 · state default / pressed / disabled / loading.
// Pressed = active scale (fast/standard, reduced-motion safe).
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
          "inline-flex items-center justify-center gap-2 font-semibold",
          "transition-transform duration-120 ease-standard enabled:active:scale-[0.98]",
          "motion-reduce:transition-none motion-reduce:active:scale-100",
          "disabled:opacity-50 disabled:cursor-not-allowed",
          size === "md" ? "h-11 px-6 text-body-lg" : "h-9 px-4 text-body",
          kind !== "link" && "rounded-pill",
          kind === "gradient-primary" && "bg-accent-gradient text-on-accent",
          kind === "quiet" && "border border-border bg-bg-elev text-text",
          kind === "destructive" && "bg-error text-on-accent",
          kind === "link" &&
            "h-auto px-0 text-link underline-offset-2 hover:underline",
          className,
        )}
        {...rest}
      >
        {loading ? (
          <Spinner
            size={20}
            kind={kind === "quiet" || kind === "link" ? "neutral" : "gradient"}
            className={
              kind === "gradient-primary" || kind === "destructive"
                ? "text-on-accent"
                : undefined
            }
          />
        ) : null}
        {children}
      </button>
    );
  },
);
