"use client";

// IconButton — design.md §8.2 (as built 2026-07-17): size md / sm · state
// default / pressed / disabled. 24px stroke icons; hit target ≥44px on md
// (design.md §5).
import { forwardRef, type ButtonHTMLAttributes, type ReactNode } from "react";
import clsx from "clsx";

export interface IconButtonProps
  extends ButtonHTMLAttributes<HTMLButtonElement> {
  size?: "md" | "sm";
  /** Accessible name — icon-only buttons must label themselves. */
  "aria-label": string;
  children: ReactNode;
}

export const IconButton = forwardRef<HTMLButtonElement, IconButtonProps>(
  function IconButton({ size = "md", className, children, ...rest }, ref) {
    return (
      <button
        ref={ref}
        type="button"
        data-size={size}
        className={clsx(
          "inline-grid place-items-center rounded-pill text-text",
          "transition-transform duration-120 ease-standard enabled:active:scale-90",
          "motion-reduce:transition-none motion-reduce:active:scale-100",
          "disabled:opacity-50 disabled:cursor-not-allowed",
          "hover:bg-border/40",
          size === "md" ? "size-11" : "size-9",
          className,
        )}
        {...rest}
      >
        {children}
      </button>
    );
  },
);
