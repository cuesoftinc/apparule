"use client";

// Popover / MenuItem — design.md §8.2b: item default / destructive /
// with-icon · contexts: PostCard ⋯ overflow (report/share), copy-link
// (MI-9 desktop), recent-searches dropdown. Desktop popover; mobile
// surfaces reuse rows inside a Sheet. Radix popover supplies behavior.
import * as RadixPopover from "@radix-ui/react-popover";
import clsx from "clsx";
import { type ComponentType, type ReactNode } from "react";

export interface PopoverProps {
  trigger: ReactNode;
  children: ReactNode;
  side?: "top" | "bottom" | "left" | "right";
  align?: "start" | "center" | "end";
  /** Test/gallery hook. */
  defaultOpen?: boolean;
}

export function Popover({
  trigger,
  children,
  side = "bottom",
  align = "end",
  defaultOpen,
}: PopoverProps) {
  return (
    <RadixPopover.Root defaultOpen={defaultOpen}>
      <RadixPopover.Trigger asChild>{trigger}</RadixPopover.Trigger>
      <RadixPopover.Portal>
        <RadixPopover.Content
          side={side}
          align={align}
          sideOffset={4}
          // Collision-clamp canon (org SKILL.md, 2026-07-19): floating
          // layers stay fully inside the viewport at every breakpoint and
          // anchor position — 8px breathing room off every edge.
          collisionPadding={8}
          // Figma master (96:1191): hairline dividers between menu items
          className="z-20 min-w-48 divide-y divide-border overflow-hidden rounded-card border border-border bg-bg-elev shadow-lg"
        >
          {children}
        </RadixPopover.Content>
      </RadixPopover.Portal>
    </RadixPopover.Root>
  );
}

export interface MenuItemProps {
  label: string;
  onSelect?: () => void;
  destructive?: boolean;
  icon?: ComponentType<{ size?: number | string; className?: string }>;
  disabled?: boolean;
}

export function MenuItem({
  label,
  onSelect,
  destructive = false,
  icon: Icon,
  disabled,
}: MenuItemProps) {
  return (
    <button
      type="button"
      role="menuitem"
      disabled={disabled}
      onClick={onSelect}
      data-destructive={destructive || undefined}
      className={clsx(
        "flex w-full items-center gap-3 px-4 py-2.5 text-left text-body",
        "hover:bg-border/30 disabled:opacity-50",
        destructive ? "text-error" : "text-text",
      )}
    >
      {Icon ? <Icon size={18} className="shrink-0" /> : null}
      {label}
    </button>
  );
}
