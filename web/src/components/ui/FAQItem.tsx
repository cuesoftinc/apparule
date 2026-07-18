"use client";

// FAQItem — design.md §8.2b (as built 2026-07-18): question + chevron ·
// state collapsed / expanded · one-open-at-a-time group · rows
// deep-linkable (#faq-n, pages.md A9b) · chevron rotates 180° on
// expand/collapse (base 200ms).
import clsx from "clsx";
import { ChevronDown } from "lucide-react";
import { createContext, useContext, useState, type ReactNode } from "react";

const FAQGroupContext = createContext<{
  openId: string | null;
  setOpenId: (id: string | null) => void;
} | null>(null);

/** One-open-at-a-time group; wraps FAQItem rows. */
export function FAQGroup({
  children,
  defaultOpenId = null,
  className,
}: {
  children: ReactNode;
  defaultOpenId?: string | null;
  className?: string;
}) {
  const [openId, setOpenId] = useState<string | null>(defaultOpenId);
  return (
    <FAQGroupContext.Provider value={{ openId, setOpenId }}>
      <div className={clsx("flex w-full max-w-[720px] flex-col", className)}>
        {children}
      </div>
    </FAQGroupContext.Provider>
  );
}

export interface FAQItemProps {
  /** Deep-link id, e.g. "faq-1" (renders as the row's DOM id). */
  id: string;
  question: string;
  /** Analytics seam — pages.md A9b `faq_open` fires from the page here. */
  onOpenChange?: (open: boolean) => void;
  children: ReactNode;
  className?: string;
}

export function FAQItem({
  id,
  question,
  onOpenChange,
  children,
  className,
}: FAQItemProps) {
  const group = useContext(FAQGroupContext);
  const [localOpen, setLocalOpen] = useState(false);
  const open = group ? group.openId === id : localOpen;
  const toggle = () => {
    if (group) {
      group.setOpenId(open ? null : id);
    } else {
      setLocalOpen((o) => !o);
    }
    onOpenChange?.(!open);
  };

  return (
    <div
      id={id}
      data-state={open ? "expanded" : "collapsed"}
      className={clsx("border-b border-border", className)}
    >
      <button
        type="button"
        aria-expanded={open}
        aria-controls={`${id}-panel`}
        onClick={toggle}
        className="flex w-full items-center justify-between gap-4 py-4 text-left"
      >
        <span className="text-body-lg font-semibold text-text">{question}</span>
        <ChevronDown
          size={20}
          data-testid="faq-chevron"
          className={clsx(
            "shrink-0 text-text-2 transition-transform duration-200 ease-standard",
            open && "rotate-180",
            "motion-reduce:transition-none",
          )}
        />
      </button>
      {open ? (
        <div id={`${id}-panel`} className="pb-4 text-body text-text-2">
          {children}
        </div>
      ) : null}
    </div>
  );
}
