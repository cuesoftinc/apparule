// Feed + explore repository — api.md §5 (ranked endpoints; rank frozen per
// cursor for its 24h lifetime).
import { apiFetch, type Page } from "@/lib/api";
import type { Post } from "../entities/post";

export interface ExploreFilters {
  q?: string;
  tags?: string[];
  price_band?: "budget" | "mid" | "premium";
  /** Turnaround-time chip (pages.md B2): only posts deliverable within N days. */
  max_turnaround_days?: number;
  /**
   * "Near me" chip: proximity RANKING by designer profile_location vs the
   * caller's (X-10 tier 1) — never a hard gate (api.md §5 extension).
   */
  near_me?: boolean;
}

function query(params: Record<string, string | undefined>): string {
  const entries = Object.entries(params).filter(
    (pair): pair is [string, string] => pair[1] !== undefined && pair[1] !== "",
  );
  if (entries.length === 0) return "";
  return `?${new URLSearchParams(entries).toString()}`;
}

export const feedRepo = {
  /** GET /api/v1/feed — cursor pagination per api.md §4 (`?cursor=&limit=`). */
  feed: (cursor?: string, limit?: number) =>
    apiFetch<Page<Post>>(
      `/v1/feed${query({ cursor, limit: limit?.toString() })}`,
    ),

  /** GET /api/v1/explore?q&tags&price_band&max_turnaround_days&near_me */
  explore: (filters: ExploreFilters = {}, cursor?: string) =>
    apiFetch<Page<Post>>(
      `/v1/explore${query({
        q: filters.q,
        tags: filters.tags?.join(","),
        price_band: filters.price_band,
        max_turnaround_days: filters.max_turnaround_days?.toString(),
        near_me: filters.near_me ? "1" : undefined,
        cursor,
      })}`,
    ),
};
