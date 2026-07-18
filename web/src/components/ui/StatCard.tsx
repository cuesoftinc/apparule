"use client";

// StatCard — design.md §8.2b Home section kit: 3 stat cards, fade-up on
// scroll-into-view (once, pages.md A3). Accuracy standard (2026-07-18):
// product claims only — ±2 cm target accuracy · 2 photos · 30-day photo
// auto-delete — never invented research statistics.
import { useEffect, useRef, useState } from "react";
import clsx from "clsx";

export interface StatCardProps {
  /** The claim headline, e.g. "±2 cm". */
  stat: string;
  label: string;
  className?: string;
}

export function StatCard({ stat, label, className }: StatCardProps) {
  const ref = useRef<HTMLDivElement>(null);
  const [visible, setVisible] = useState(false);

  // fade-up once on scroll-into-view
  useEffect(() => {
    const node = ref.current;
    if (!node || typeof IntersectionObserver === "undefined") {
      setVisible(true);
      return;
    }
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setVisible(true);
          observer.disconnect();
        }
      },
      { threshold: 0.3 },
    );
    observer.observe(node);
    return () => observer.disconnect();
  }, []);

  return (
    <div
      ref={ref}
      data-visible={visible}
      className={clsx(
        "flex flex-col gap-2 rounded-card border border-border bg-bg-elev p-6",
        "transition-all duration-250 ease-standard motion-reduce:transition-none",
        visible ? "translate-y-0 opacity-100" : "translate-y-4 opacity-0",
        "motion-reduce:translate-y-0 motion-reduce:opacity-100",
        className,
      )}
    >
      <span className="tnum bg-accent-gradient bg-clip-text text-display font-bold text-transparent">
        {stat}
      </span>
      <span className="text-body text-text-2">{label}</span>
    </div>
  );
}
