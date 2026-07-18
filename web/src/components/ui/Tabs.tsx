"use client";

// Tabs — design.md §8.2b (as built 2026-07-17): active: first / second ·
// kind: text ("As customer / As designer") / icon (grid `icon/grid-3x3` ·
// saved) · underline indicator.
import clsx from "clsx";
import { Bookmark, Grid3x3 } from "lucide-react";

export interface TabsProps {
  kind?: "text" | "icon";
  /** Two-item set per the contract. */
  labels?: [string, string];
  active: "first" | "second";
  onChange: (active: "first" | "second") => void;
  className?: string;
}

export function Tabs({
  kind = "text",
  labels = ["As customer", "As designer"],
  active,
  onChange,
  className,
}: TabsProps) {
  const items: { key: "first" | "second"; content: React.ReactNode; name: string }[] =
    kind === "text"
      ? [
          { key: "first", content: labels[0], name: labels[0] },
          { key: "second", content: labels[1], name: labels[1] },
        ]
      : [
          { key: "first", content: <Grid3x3 size={24} />, name: "Grid" },
          { key: "second", content: <Bookmark size={24} />, name: "Saved" },
        ];

  return (
    <div
      role="tablist"
      data-kind={kind}
      className={clsx("flex border-b border-border", className)}
    >
      {items.map((item) => {
        const isActive = active === item.key;
        return (
          <button
            key={item.key}
            role="tab"
            type="button"
            aria-selected={isActive}
            aria-label={kind === "icon" ? item.name : undefined}
            onClick={() => onChange(item.key)}
            className={clsx(
              "relative flex h-11 flex-1 items-center justify-center gap-2 text-body font-semibold",
              "transition-colors duration-120 ease-standard motion-reduce:transition-none",
              isActive ? "text-text" : "text-text-2 hover:text-text",
            )}
          >
            {item.content}
            {isActive ? (
              <span
                data-testid="tab-indicator"
                className="absolute inset-x-0 bottom-0 h-0.5 bg-text"
              />
            ) : null}
          </button>
        );
      })}
    </div>
  );
}
