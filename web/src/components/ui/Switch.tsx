"use client";

// Switch — design.md §8.2b: state on / off × enabled / disabled.
// Radix switch supplies the a11y/behavior (reuse policy: invisible
// primitives allowed); visuals are token-built.
import * as RadixSwitch from "@radix-ui/react-switch";
import clsx from "clsx";

export interface SwitchProps {
  checked: boolean;
  onCheckedChange: (checked: boolean) => void;
  disabled?: boolean;
  /** Accessible name for the control. */
  "aria-label": string;
  className?: string;
}

export function Switch({
  checked,
  onCheckedChange,
  disabled = false,
  className,
  ...rest
}: SwitchProps) {
  return (
    <RadixSwitch.Root
      checked={checked}
      onCheckedChange={onCheckedChange}
      disabled={disabled}
      className={clsx(
        "relative h-6 w-11 shrink-0 rounded-pill transition-colors duration-200 ease-standard",
        "motion-reduce:transition-none",
        checked ? "bg-accent-gradient" : "bg-border",
        disabled && "opacity-50 cursor-not-allowed",
        className,
      )}
      {...rest}
    >
      <RadixSwitch.Thumb
        className={clsx(
          "block size-5 translate-x-0.5 rounded-pill bg-bg-elev shadow-sm",
          "transition-transform duration-200 ease-standard motion-reduce:transition-none",
          "data-[state=checked]:translate-x-[22px]",
        )}
      />
    </RadixSwitch.Root>
  );
}
