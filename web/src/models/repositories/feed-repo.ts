// Feed + explore repository — api.md §5 (ranked endpoints; rank frozen per
// cursor for its 24h lifetime).
import { apiFetch, type Page } from "@/lib/api";
import type { Post } from "../entities/post";

export interface ExploreFilters {
  q?: string;
  tags?: string[];
  price_band?: "budget" | "mid" | "premium";
}

function query(params: Record<string, string | undefined>): string {
  const entries = Object.entries(params).filter(
    (pair): pair is [string, string] => pair[1] !== undefined && pair[1] !== "",
  );
  if (entries.length === 0) return "";
  return `?${new URLSearchParams(entries).toString()}`;
}

export const feedRepo = {
  /** GET /api/v1/feed */
  feed: (cursor?: string) =>
    apiFetch<Page<Post>>(`/v1/feed${query({ cursor })}`),

  /** GET /api/v1/explore?q&tags&price_band */
  explore: (filters: ExploreFilters = {}, cursor?: string) =>
    apiFetch<Page<Post>>(
      `/v1/explore${query({
        q: filters.q,
        tags: filters.tags?.join(","),
        price_band: filters.price_band,
        cursor,
      })}`,
    ),
};
