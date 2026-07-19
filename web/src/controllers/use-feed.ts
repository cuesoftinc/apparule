"use client";

// Feed controller — owns feed state; PostCard views render from it.
// Likes/saves are optimistic everywhere (MI-18): flip first, roll back on
// failure (the view layer re-toasts with Retry).
import { useCallback, useEffect, useRef, useState } from "react";
import type { Post } from "@/models";
import { feedRepo, type ExploreFilters } from "@/models/repositories/feed-repo";
import { postsRepo } from "@/models/repositories/posts-repo";

export interface FeedState {
  posts: Post[];
  loading: boolean;
  loadingMore: boolean;
  error: string | null;
  /** MI-6: caught-up divider once the ranked page is exhausted. */
  caughtUp: boolean;
}

function togglePost(
  posts: Post[],
  id: string,
  mutate: (post: Post) => Post,
): Post[] {
  return posts.map((p) => (p.id === id ? mutate(p) : p));
}

/**
 * MI-6 feed page size: small enough that the seeded 7-post feed exercises
 * cursor pagination from boot (prefetch at 3 cards from the end, skeleton
 * ×2 during the fetch). Explore keeps the api.md §4 default (50).
 */
export const FEED_PAGE_SIZE = 4;

export function useFeed(mode: "feed" | "explore" = "feed", filters?: ExploreFilters) {
  const [state, setState] = useState<FeedState>({
    posts: [],
    loading: true,
    loadingMore: false,
    error: null,
    caughtUp: false,
  });
  const cursorRef = useRef<string | null>(null);
  const loadingMoreRef = useRef(false);
  const filtersKey = JSON.stringify(filters ?? {});

  // Effect-safe fetch (react-hooks/set-state-in-effect): setState only in
  // promise callbacks; `loading` starts true and reload() re-arms it from
  // event handlers.
  const load = useCallback(() => {
    const request =
      mode === "feed"
        ? feedRepo.feed(undefined, FEED_PAGE_SIZE)
        : feedRepo.explore(JSON.parse(filtersKey));
    return request.then(
      (page) => {
        cursorRef.current = page.next_cursor;
        setState({
          posts: page.items,
          loading: false,
          loadingMore: false,
          error: null,
          caughtUp: page.next_cursor === null,
        });
      },
      (e: unknown) => {
        setState((s) => ({
          ...s,
          loading: false,
          error: e instanceof Error ? e.message : "Failed to load feed",
        }));
      },
    );
  }, [mode, filtersKey]);

  useEffect(() => {
    void load();
  }, [load]);

  /** Event-handler refresh: shows the skeleton again, then refetches. */
  const reload = useCallback(() => {
    setState((s) => ({ ...s, loading: true, error: null }));
    return load();
  }, [load]);

  const loadMore = useCallback(async () => {
    const cursor = cursorRef.current;
    // The MI-6 intersection prefetch can re-fire while a page is in
    // flight — the ref gate keeps one request per cursor.
    if (!cursor || loadingMoreRef.current) return;
    loadingMoreRef.current = true;
    setState((s) => ({ ...s, loadingMore: true }));
    try {
      const page =
        mode === "feed"
          ? await feedRepo.feed(cursor, FEED_PAGE_SIZE)
          : await feedRepo.explore(JSON.parse(filtersKey), cursor);
      cursorRef.current = page.next_cursor;
      setState((s) => ({
        ...s,
        posts: [...s.posts, ...page.items],
        loadingMore: false,
        caughtUp: page.next_cursor === null,
      }));
    } catch {
      setState((s) => ({ ...s, loadingMore: false }));
    } finally {
      loadingMoreRef.current = false;
    }
  }, [mode, filtersKey]);

  /**
   * Re-sync one rendered item from the server — the in-app post modal
   * (PostDetailView over its own usePost) mutates likes/saves/comments
   * independently, so the owning list refreshes that post when the modal
   * closes; the feed card never shows stale counts (PR #102 review).
   */
  const syncPost = useCallback(async (id: string) => {
    try {
      const fresh = await postsRepo.get(id);
      setState((s) => ({
        ...s,
        posts: togglePost(s.posts, id, () => fresh),
      }));
    } catch {
      // keep the rendered item; the next reload converges it
    }
  }, []);

  /** Optimistic like toggle (MI-1/MI-2 + MI-18 rollback). */
  const toggleLike = useCallback(async (post: Post) => {
    const liked = !post.liked;
    const delta = liked ? 1 : -1;
    setState((s) => ({
      ...s,
      posts: togglePost(s.posts, post.id, (p) => ({
        ...p,
        liked,
        like_count: p.like_count + delta,
      })),
    }));
    try {
      await (liked ? postsRepo.like(post.id) : postsRepo.unlike(post.id));
    } catch {
      setState((s) => ({
        ...s,
        posts: togglePost(s.posts, post.id, (p) => ({
          ...p,
          liked: !liked,
          like_count: p.like_count - delta,
        })),
      }));
      throw new Error("like_failed");
    }
  }, []);

  /** Optimistic save toggle (MI-3 + MI-18 rollback). */
  const toggleSave = useCallback(async (post: Post) => {
    const saved = !post.saved;
    setState((s) => ({
      ...s,
      posts: togglePost(s.posts, post.id, (p) => ({ ...p, saved })),
    }));
    try {
      await (saved ? postsRepo.save(post.id) : postsRepo.unsave(post.id));
    } catch {
      setState((s) => ({
        ...s,
        posts: togglePost(s.posts, post.id, (p) => ({ ...p, saved: !saved })),
      }));
      throw new Error("save_failed");
    }
  }, []);

  return { ...state, reload, loadMore, syncPost, toggleLike, toggleSave };
}
