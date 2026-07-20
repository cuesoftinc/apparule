"use client";

// CodeSnippetTabs — design.md §8.2b Home section kit: the A7c self-host
// snippet as a mirrored Docker Compose | Helm pair (Figma proposal 415:2).
// Tab grammar per the frame: Micro/12 Semi Bold labels on the dark block,
// active tab = 2px link underline; the copy pill keeps the CodeSnippetBlock
// grammar (Copy → ✓ Copied morph) and always copies the ACTIVE tab's full
// two-line block — the rendered `$ ` prompts are decorative (select-none)
// and stay out of the payload. Tablist semantics: roving tabindex +
// Arrow/Home/End focus.
import { useRef, useState } from "react";
import clsx from "clsx";
import { Check, Copy } from "lucide-react";

export interface CodeSnippetTab {
  label: string;
  /** Newline-separated shell commands (rendered one per line). */
  code: string;
}

export interface CodeSnippetTabsProps {
  tabs: CodeSnippetTab[];
  /** Accessible name for the tablist. */
  label?: string;
  className?: string;
}

export function CodeSnippetTabs({
  tabs,
  label = "Install method",
  className,
}: CodeSnippetTabsProps) {
  const [active, setActive] = useState(0);
  const [copied, setCopied] = useState(false);
  const tabRefs = useRef<(HTMLButtonElement | null)[]>([]);

  async function copy() {
    try {
      await navigator.clipboard.writeText(tabs[active].code);
    } catch {
      // clipboard unavailable — morph anyway so the action never feels dead
    }
    setCopied(true);
    setTimeout(() => setCopied(false), 1500);
  }

  function select(i: number) {
    setActive(i);
    setCopied(false);
  }

  function onTabKeyDown(event: React.KeyboardEvent, index: number) {
    const last = tabs.length - 1;
    let next: number | null = null;
    if (event.key === "ArrowRight") next = index === last ? 0 : index + 1;
    else if (event.key === "ArrowLeft") next = index === 0 ? last : index - 1;
    else if (event.key === "Home") next = 0;
    else if (event.key === "End") next = last;
    if (next === null) return;
    event.preventDefault();
    select(next);
    tabRefs.current[next]?.focus();
  }

  return (
    <div
      className={clsx(
        "rounded-card border border-border bg-text/95",
        className,
      )}
    >
      <div className="flex items-start gap-4 pl-5 pr-3 pt-3">
        <div role="tablist" aria-label={label} className="flex flex-1 gap-4">
          {tabs.map((tab, i) => {
            const isActive = i === active;
            return (
              <button
                key={tab.label}
                ref={(el) => {
                  tabRefs.current[i] = el;
                }}
                type="button"
                role="tab"
                aria-selected={isActive}
                tabIndex={isActive ? 0 : -1}
                onClick={() => select(i)}
                onKeyDown={(event) => onTabKeyDown(event, i)}
                className={clsx(
                  "flex flex-col gap-[5px] text-micro font-semibold",
                  "transition-colors duration-120 ease-standard motion-reduce:transition-none",
                  isActive ? "text-bg" : "text-bg/60 hover:text-bg",
                )}
              >
                {tab.label}
                <span
                  aria-hidden="true"
                  className={clsx(
                    "h-0.5 w-full",
                    isActive ? "bg-link" : "bg-transparent",
                  )}
                />
              </button>
            );
          })}
        </div>
        {/* Figma master (Stage 5): labeled Copy pill; ✓ Copied turns success */}
        <button
          type="button"
          aria-label={copied ? "Copied" : "Copy commands"}
          onClick={copy}
          className={clsx(
            "flex h-7 shrink-0 items-center gap-1.5 rounded-pill border px-3 text-micro font-semibold",
            "transition-colors duration-120 ease-standard motion-reduce:transition-none",
            copied
              ? "border-success text-success"
              : "border-bg/30 text-bg hover:bg-bg/10",
          )}
        >
          {copied ? (
            <Check
              size={14}
              data-testid="copied-check"
              className="text-success"
            />
          ) : (
            <Copy size={14} />
          )}
          {copied ? "Copied" : "Copy"}
        </button>
      </div>
      <div className="flex flex-col gap-1 overflow-x-auto px-5 pb-3.5 pt-3 font-mono text-body text-bg">
        {tabs[active].code.split("\n").map((line) => (
          <code key={line} className="whitespace-nowrap">
            <span className="select-none text-bg/50">$ </span>
            {line}
          </code>
        ))}
      </div>
    </div>
  );
}
