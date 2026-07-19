"use client";

// Tooltip — design.md §8.2b: placement top / bottom · single-line.
// Radix tooltip provides the behavior; visuals are token-built.
import * as RadixTooltip from "@radix-ui/react-tooltip";
import { type ReactNode } from "react";

export interface TooltipProps {
  /** Single-line tooltip copy. */
  label: string;
  placement?: "top" | "bottom";
  children: ReactNode;
  /** Test/gallery hook: render the tooltip open. */
  defaultOpen?: boolean;
}

export function Tooltip({
  label,
  placement = "top",
  children,
  defaultOpen,
}: TooltipProps) {
  return (
    <RadixTooltip.Provider delayDuration={300}>
      <RadixTooltip.Root defaultOpen={defaultOpen}>
        <RadixTooltip.Trigger asChild>{children}</RadixTooltip.Trigger>
        <RadixTooltip.Portal>
          <RadixTooltip.Content
            side={placement}
            sideOffset={6}
            // Collision-clamp canon (org SKILL.md, 2026-07-19): tooltips
            // shift to stay inside the viewport — 8px pad off every edge.
            collisionPadding={8}
            className="z-20 whitespace-nowrap rounded-card bg-text px-2.5 py-1.5 text-caption text-bg shadow-md"
          >
            {label}
          </RadixTooltip.Content>
        </RadixTooltip.Portal>
      </RadixTooltip.Root>
    </RadixTooltip.Provider>
  );
}
