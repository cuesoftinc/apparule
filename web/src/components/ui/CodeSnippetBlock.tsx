"use client";

// CodeSnippetBlock — design.md §8.2b Home section kit: `docker compose up`
// snippet with copy button → ✓ morph (pages.md A7/A7c; shared asset).
import { useState } from "react";
import clsx from "clsx";
import { Check, Copy } from "lucide-react";

export interface CodeSnippetBlockProps {
  code?: string;
  className?: string;
}

export function CodeSnippetBlock({
  code = "docker compose up -d",
  className,
}: CodeSnippetBlockProps) {
  const [copied, setCopied] = useState(false);

  async function copy() {
    try {
      await navigator.clipboard.writeText(code);
    } catch {
      // clipboard unavailable — morph anyway so the action never feels dead
    }
    setCopied(true);
    setTimeout(() => setCopied(false), 1500);
  }

  return (
    <div
      className={clsx(
        "flex items-center gap-3 rounded-card border border-border bg-text/95 px-4 py-3",
        className,
      )}
    >
      <code className="flex-1 overflow-x-auto whitespace-nowrap font-mono text-body text-bg">
        <span className="select-none text-bg/50">$ </span>
        {code}
      </code>
      {/* Figma master (Stage 5): labeled Copy pill; ✓ Copied turns success */}
      <button
        type="button"
        aria-label={copied ? "Copied" : "Copy command"}
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
          <Check size={14} data-testid="copied-check" className="text-success" />
        ) : (
          <Copy size={14} />
        )}
        {copied ? "Copied" : "Copy"}
      </button>
    </div>
  );
}
