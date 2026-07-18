"use client";

// Select / OptionRow — design.md §8.2b: trigger default / focus / error /
// disabled · OptionRow default / selected (check) · contexts:
// decline-reason enum, dispute reason picker, NG-state, bank (KYC),
// language. Radix select supplies behavior; visuals are token-built.
import * as RadixSelect from "@radix-ui/react-select";
import clsx from "clsx";
import { Check, ChevronDown } from "lucide-react";

export interface SelectOption {
  value: string;
  label: string;
}

export interface SelectProps {
  options: SelectOption[];
  value: string | undefined;
  onValueChange: (value: string) => void;
  placeholder?: string;
  error?: string;
  disabled?: boolean;
  /** Accessible name for the trigger. */
  "aria-label": string;
  className?: string;
}

export function Select({
  options,
  value,
  onValueChange,
  placeholder = "Select…",
  error,
  disabled,
  className,
  ...rest
}: SelectProps) {
  return (
    <div className={clsx("flex flex-col gap-1", className)}>
      <RadixSelect.Root
        value={value}
        onValueChange={onValueChange}
        disabled={disabled}
      >
        <RadixSelect.Trigger
          aria-invalid={error ? true : undefined}
          className={clsx(
            // Figma form-kit frame (74:801): 14px value, 1.5px error border,
            // 2px accent focus, 40% disabled.
            "flex h-11 items-center justify-between gap-2 rounded-card bg-bg-elev px-3 text-body text-text",
            "transition-colors duration-120 ease-standard motion-reduce:transition-none",
            "data-[placeholder]:text-text-2 disabled:opacity-40",
            error
              ? "border-[1.5px] border-error"
              : "border border-border focus:border-2 focus:border-accent-start",
          )}
          {...rest}
        >
          <RadixSelect.Value placeholder={placeholder} />
          <RadixSelect.Icon>
            <ChevronDown size={18} className="text-text-2" />
          </RadixSelect.Icon>
        </RadixSelect.Trigger>
        <RadixSelect.Portal>
          <RadixSelect.Content
            position="popper"
            sideOffset={4}
            className="z-20 max-h-72 min-w-[var(--radix-select-trigger-width)] overflow-y-auto rounded-card border border-border bg-bg-elev py-1 shadow-lg"
          >
            <RadixSelect.Viewport>
              {options.map((option) => (
                <OptionRow key={option.value} option={option} />
              ))}
            </RadixSelect.Viewport>
          </RadixSelect.Content>
        </RadixSelect.Portal>
      </RadixSelect.Root>
      {error ? <span className="text-caption text-error">{error}</span> : null}
    </div>
  );
}

/** OptionRow — default / selected (check trailing). */
export function OptionRow({ option }: { option: SelectOption }) {
  return (
    <RadixSelect.Item
      value={option.value}
      className={clsx(
        "flex cursor-pointer items-center justify-between gap-3 px-3 py-2.5 text-body text-text outline-none",
        "data-[highlighted]:bg-border/30 data-[state=checked]:font-semibold",
      )}
    >
      <RadixSelect.ItemText>{option.label}</RadixSelect.ItemText>
      <RadixSelect.ItemIndicator>
        <Check size={16} className="text-text" />
      </RadixSelect.ItemIndicator>
    </RadixSelect.Item>
  );
}
