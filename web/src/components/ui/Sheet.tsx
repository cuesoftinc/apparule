"use client";

// Sheet — design.md §3/§8.2: bottom sheet mobile / centered modal desktop ·
// with/without stepper header. All secondary flows live in sheets. Radix
// dialog supplies focus trap/ARIA; visuals are token-built. On <md screens
// the panel docks to the bottom; ≥md it centers (desktop modal).
import * as RadixDialog from "@radix-ui/react-dialog";
import clsx from "clsx";
import { X } from "lucide-react";
import { useRef, type ReactNode } from "react";

export interface SheetStepper {
  steps: string[];
  /** 0-based current step; progress bar fills with 300ms ease (MI-10). */
  current: number;
}

export type SheetSize = "default" | "wide";

export interface SheetProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  title: string;
  /** Optional MI-10 stepper header (Measurements → Notes/Budget → Review). */
  stepper?: SheetStepper;
  /**
   * Desktop width: `default` is the 480px secondary-flow modal; `wide` is
   * the two-column post-detail modal (B2's IG desktop pattern) — a real
   * width, not a max-width, because same-property Tailwind utilities
   * resolve by stylesheet order (layout canon), so callers must never
   * try to out-class the base `md:w-*`.
   */
  size?: SheetSize;
  children: ReactNode;
  className?: string;
}

// Wide clamps to the viewport (floating-layer canon) below its 896px
// (max-w-4xl-equivalent) desktop width.
const SIZE_CLASSES: Record<SheetSize, string> = {
  default: "md:w-[480px]",
  wide: "md:w-[min(56rem,calc(100vw-4rem))]",
};

export function Sheet({
  open,
  onOpenChange,
  title,
  stepper,
  size = "default",
  children,
  className,
}: SheetProps) {
  // Sheets are controlled dialogs with no RadixDialog.Trigger, so Radix's
  // default close autofocus targets a null triggerRef and focus falls to
  // <body> (2026-07-21 a11y audit). Capture the opener ourselves —
  // onOpenAutoFocus fires before Radix moves focus into the panel — and
  // send focus back on close.
  const returnFocusRef = useRef<HTMLElement | null>(null);
  return (
    <RadixDialog.Root open={open} onOpenChange={onOpenChange}>
      <RadixDialog.Portal>
        <RadixDialog.Overlay className="fixed inset-0 z-30 bg-black/50 motion-reduce:animate-none" />
        <RadixDialog.Content
          aria-modal="true"
          onOpenAutoFocus={() => {
            returnFocusRef.current =
              document.activeElement instanceof HTMLElement
                ? document.activeElement
                : null;
          }}
          onCloseAutoFocus={(event) => {
            // preventDefault also skips Radix's own (null-trigger) handler.
            event.preventDefault();
            const opener = returnFocusRef.current;
            returnFocusRef.current = null;
            if (opener?.isConnected) opener.focus();
          }}
          className={clsx(
            // z-40 sheet/modal layer; bottom sheet <md, centered modal ≥md
            "fixed z-40 flex max-h-[85vh] w-full flex-col overflow-hidden bg-bg-elev",
            "inset-x-0 bottom-0 rounded-t-card shadow-[0_-4px_8px_rgba(0,0,0,0.2)]",
            "md:inset-x-auto md:bottom-auto md:left-1/2 md:top-1/2 md:-translate-x-1/2 md:-translate-y-1/2 md:rounded-card md:shadow-lg",
            SIZE_CLASSES[size],
            className,
          )}
        >
          {/* Figma master (50:296): mobile grabber, centered 16px title */}
          <div className="flex justify-center pt-2 md:hidden" aria-hidden>
            <span className="h-1 w-9 rounded-[2px] bg-border" />
          </div>
          <header className="flex items-center gap-3 px-4 py-3">
            <span className="size-9 shrink-0" aria-hidden />
            <RadixDialog.Title className="flex-1 text-center text-body-lg font-semibold text-text">
              {title}
            </RadixDialog.Title>
            <RadixDialog.Close
              aria-label="Close"
              className="grid size-9 shrink-0 place-items-center rounded-pill text-text hover:bg-border/40"
            >
              <X size={24} />
            </RadixDialog.Close>
          </header>
          {stepper ? <StepperHeader stepper={stepper} /> : null}
          <div className="overflow-y-auto p-4">{children}</div>
        </RadixDialog.Content>
      </RadixDialog.Portal>
    </RadixDialog.Root>
  );
}

// Figma master (50:256): a full-bleed 4px progress track under the header
// and a centered "Step n of N · Label" caption.
function StepperHeader({ stepper }: { stepper: SheetStepper }) {
  const progress = ((stepper.current + 1) / stepper.steps.length) * 100;
  return (
    <div data-testid="sheet-stepper">
      <div className="h-1 w-full bg-border">
        <div
          className="h-full bg-accent-gradient transition-[width] duration-300 ease-standard motion-reduce:transition-none"
          style={{ width: `${progress}%` }}
        />
      </div>
      <p
        aria-current="step"
        className="pt-2 text-center text-caption text-text-2"
      >
        Step {stepper.current + 1} of {stepper.steps.length} ·{" "}
        {stepper.steps[stepper.current]}
      </p>
    </div>
  );
}
