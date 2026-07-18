"use client";

// Sheet — design.md §3/§8.2: bottom sheet mobile / centered modal desktop ·
// with/without stepper header. All secondary flows live in sheets. Radix
// dialog supplies focus trap/ARIA; visuals are token-built. On <md screens
// the panel docks to the bottom; ≥md it centers (desktop modal).
import * as RadixDialog from "@radix-ui/react-dialog";
import clsx from "clsx";
import { X } from "lucide-react";
import { type ReactNode } from "react";

export interface SheetStepper {
  steps: string[];
  /** 0-based current step; progress bar fills with 300ms ease (MI-10). */
  current: number;
}

export interface SheetProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  title: string;
  /** Optional MI-10 stepper header (Measurements → Notes/Budget → Review). */
  stepper?: SheetStepper;
  children: ReactNode;
  className?: string;
}

export function Sheet({
  open,
  onOpenChange,
  title,
  stepper,
  children,
  className,
}: SheetProps) {
  return (
    <RadixDialog.Root open={open} onOpenChange={onOpenChange}>
      <RadixDialog.Portal>
        <RadixDialog.Overlay className="fixed inset-0 z-30 bg-black/50 motion-reduce:animate-none" />
        <RadixDialog.Content
          className={clsx(
            // z-40 sheet/modal layer; bottom sheet <md, centered modal ≥md
            "fixed z-40 flex max-h-[85vh] w-full flex-col overflow-hidden bg-bg-elev shadow-lg",
            "inset-x-0 bottom-0 rounded-t-[8px]",
            "md:inset-x-auto md:bottom-auto md:left-1/2 md:top-1/2 md:w-[480px] md:-translate-x-1/2 md:-translate-y-1/2 md:rounded-card",
            className,
          )}
        >
          <header className="flex items-center justify-between gap-3 border-b border-border px-6 py-4">
            <RadixDialog.Title className="text-title font-semibold text-text">
              {title}
            </RadixDialog.Title>
            <RadixDialog.Close
              aria-label="Close"
              className="grid size-9 place-items-center rounded-pill text-text-2 hover:bg-border/40 hover:text-text"
            >
              <X size={20} />
            </RadixDialog.Close>
          </header>
          {stepper ? <StepperHeader stepper={stepper} /> : null}
          <div className="overflow-y-auto px-6 py-4">{children}</div>
        </RadixDialog.Content>
      </RadixDialog.Portal>
    </RadixDialog.Root>
  );
}

function StepperHeader({ stepper }: { stepper: SheetStepper }) {
  const progress = ((stepper.current + 1) / stepper.steps.length) * 100;
  return (
    <div data-testid="sheet-stepper" className="border-b border-border px-6 py-3">
      <div className="mb-2 flex justify-between">
        {stepper.steps.map((step, i) => (
          <span
            key={step}
            aria-current={i === stepper.current ? "step" : undefined}
            className={clsx(
              "text-caption",
              i <= stepper.current ? "font-semibold text-text" : "text-text-2",
            )}
          >
            {step}
          </span>
        ))}
      </div>
      <div className="h-1 overflow-hidden rounded-pill bg-border">
        <div
          className="h-full bg-accent-gradient transition-[width] duration-300 ease-standard motion-reduce:transition-none"
          style={{ width: `${progress}%` }}
        />
      </div>
    </div>
  );
}
