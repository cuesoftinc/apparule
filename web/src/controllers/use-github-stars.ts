"use client";

// GitHub star-count controller (pages.md A1/A7b): fetched once client-side,
// shared between the nav badge and the A7b developer badge, animating a
// count-up once per session (A1 "animates count-up once"). Failures resolve
// to null → the badge keeps its neutral "Star" label.
import { useEffect, useState } from "react";
import { githubRepo } from "@/models/repositories/github-repo";

const COUNT_UP_MS = 800;

// Module-level cache: one fetch and one count-up per session, however many
// components subscribe.
let cached: number | null | undefined;
let inflight: Promise<number | null> | null = null;
let countUpPlayed = false;

/** Test hook — reset the module cache between cases. */
export function resetGithubStarsCache(): void {
  cached = undefined;
  inflight = null;
  countUpPlayed = false;
}

function prefersReducedMotion(): boolean {
  return (
    typeof window === "undefined" ||
    typeof window.matchMedia !== "function" ||
    window.matchMedia("(prefers-reduced-motion: reduce)").matches
  );
}

/** Displayed star count (null until fetched / on failure). */
export function useGithubStars(): number | null {
  const [display, setDisplay] = useState<number | null>(
    typeof cached === "number" ? cached : null,
  );

  useEffect(() => {
    // Effect-safe (react-hooks/set-state-in-effect): setDisplay only runs
    // in promise/rAF callbacks; a warm cache resolves immediately.
    const source =
      cached !== undefined
        ? Promise.resolve(cached)
        : (inflight ??= githubRepo.stars());
    let raf = 0;
    let cancelled = false;

    void source.then((value) => {
      cached = value;
      if (cancelled) return;
      if (value === null || countUpPlayed || prefersReducedMotion()) {
        setDisplay(value);
        return;
      }
      // Count-up 0 → value over COUNT_UP_MS, once per session.
      countUpPlayed = true;
      const start = performance.now();
      const tick = (now: number) => {
        const t = Math.min((now - start) / COUNT_UP_MS, 1);
        // ease-out — settles gently like the Figma spec's entrance easing
        const eased = 1 - (1 - t) * (1 - t);
        setDisplay(Math.round(value * eased));
        if (t < 1 && !cancelled) raf = requestAnimationFrame(tick);
      };
      raf = requestAnimationFrame(tick);
    });

    return () => {
      cancelled = true;
      if (raf) cancelAnimationFrame(raf);
    };
  }, []);

  return display;
}
