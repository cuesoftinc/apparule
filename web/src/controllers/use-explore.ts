"use client";

// Explore controller (B2): masonry browse via the explore feed, filter
// chips (style tags + price bands — the api.md §5 contract set), submitted
// search → sectioned results (Designers above Posts), and the
// recent-searches dropdown (local view preference, capped at 5).
import { useCallback, useEffect, useMemo, useState } from "react";
import type { UserSummary } from "@/models";
import type { ExploreFilters } from "@/models/repositories/feed-repo";
import { designerRepo } from "@/models/repositories/designer-repo";
import { postsRepo } from "@/models/repositories/posts-repo";
import { useFeed } from "./use-feed";

const RECENT_KEY = "apparule.explore.recent";
const RECENT_MAX = 5;

function readRecent(): string[] {
  if (typeof window === "undefined") return [];
  try {
    const raw = window.localStorage.getItem(RECENT_KEY);
    const parsed = raw ? (JSON.parse(raw) as unknown) : [];
    return Array.isArray(parsed) ? parsed.filter((v) => typeof v === "string") : [];
  } catch {
    return [];
  }
}

export function useExplore() {
  const [query, setQuery] = useState("");
  /** Submitted query — swaps the masonry for sectioned results. */
  const [submitted, setSubmitted] = useState<string | null>(null);
  const [tags, setTags] = useState<string[]>([]);
  const [priceBand, setPriceBand] = useState<
    "budget" | "mid" | "premium" | undefined
  >(undefined);
  // Lazy init: reads localStorage once; hydration-safe because the recent
  // dropdown only renders after a client-side focus interaction.
  const [recent, setRecent] = useState<string[]>(readRecent);
  const [designers, setDesigners] = useState<UserSummary[]>([]);
  const [designersLoading, setDesignersLoading] = useState(false);

  const filters: ExploreFilters = useMemo(
    () => ({
      q: submitted ?? undefined,
      tags: tags.length > 0 ? tags : undefined,
      price_band: priceBand,
    }),
    [submitted, tags, priceBand],
  );

  const feed = useFeed("explore", filters);

  // Designers section of the search-results state. Loading is armed in the
  // submit/clear handlers (react-hooks/set-state-in-effect); the effect only
  // fetches and settles in promise callbacks.
  useEffect(() => {
    if (!submitted) return;
    let cancelled = false;
    designerRepo.search(submitted).then(
      (page) => {
        if (cancelled) return;
        setDesigners(page.items);
        setDesignersLoading(false);
      },
      () => {
        if (!cancelled) setDesignersLoading(false);
      },
    );
    return () => {
      cancelled = true;
    };
  }, [submitted]);

  const submit = useCallback((raw?: string) => {
    const q = (raw ?? "").trim();
    setQuery(q);
    setSubmitted(q.length > 0 ? q : null);
    setDesigners([]);
    setDesignersLoading(q.length > 0);
    if (q.length > 0) {
      setRecent((prev) => {
        const next = [q, ...prev.filter((r) => r !== q)].slice(0, RECENT_MAX);
        try {
          window.localStorage.setItem(RECENT_KEY, JSON.stringify(next));
        } catch {
          // storage unavailable — dropdown just won't persist
        }
        return next;
      });
    }
  }, []);

  const clearSearch = useCallback(() => {
    setQuery("");
    setSubmitted(null);
    setDesigners([]);
    setDesignersLoading(false);
  }, []);

  const toggleTag = useCallback((tag: string) => {
    setTags((prev) =>
      prev.includes(tag) ? prev.filter((t) => t !== tag) : [...prev, tag],
    );
  }, []);

  /** Optimistic MI-7 morph on a Designers-section row. */
  const toggleDesignerFollow = useCallback(async (row: UserSummary) => {
    const on = !row.viewer_follows;
    setDesigners((prev) =>
      prev.map((r) =>
        r.username === row.username ? { ...r, viewer_follows: on } : r,
      ),
    );
    try {
      await (on
        ? postsRepo.follow(row.username)
        : postsRepo.unfollow(row.username));
    } catch {
      setDesigners((prev) =>
        prev.map((r) =>
          r.username === row.username
            ? { ...r, viewer_follows: row.viewer_follows }
            : r,
        ),
      );
      throw new Error("follow_failed");
    }
  }, []);

  return {
    ...feed,
    query,
    setQuery,
    submitted,
    submit,
    clearSearch,
    recent,
    tags,
    toggleTag,
    priceBand,
    setPriceBand,
    designers,
    designersLoading,
    toggleDesignerFollow,
  };
}
