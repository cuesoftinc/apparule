// Feed controller — optimistic toggles (MI-18) and the post-modal sync
// seam: PostDetailView mutates its own usePost state, so the owning list
// re-syncs the item on modal close (PR #102 review).
import { beforeEach, describe, expect, it, vi } from "vitest";
import { act, renderHook, waitFor } from "@testing-library/react";
import type { Post } from "@/models";

const feed = vi.fn();
const explore = vi.fn();
vi.mock("@/models/repositories/feed-repo", () => ({
  feedRepo: {
    feed: (...a: unknown[]) => feed(...a),
    explore: (...a: unknown[]) => explore(...a),
  },
}));

const get = vi.fn();
const like = vi.fn();
const unlike = vi.fn();
const save = vi.fn();
const unsave = vi.fn();
vi.mock("@/models/repositories/posts-repo", () => ({
  postsRepo: {
    get: (...a: unknown[]) => get(...a),
    like: (...a: unknown[]) => like(...a),
    unlike: (...a: unknown[]) => unlike(...a),
    save: (...a: unknown[]) => save(...a),
    unsave: (...a: unknown[]) => unsave(...a),
  },
}));

import { useFeed } from "./use-feed";

function post(id: string, overrides: Partial<Post> = {}): Post {
  return {
    id,
    designer: {
      id: "des-1",
      username: "amara.designs",
      display_name: "Amara Designs",
      avatar_url: null,
      verified: true,
    },
    caption: `caption-${id}`,
    style_tags: ["ankara"],
    base_price_cents: 4_500_000,
    currency: "NGN",
    turnaround_days: 14,
    media: [],
    like_count: 3,
    comment_count: 1,
    liked: false,
    saved: false,
    created_at: new Date().toISOString(),
    ...overrides,
  };
}

beforeEach(() => {
  feed.mockReset();
  get.mockReset();
  like.mockReset();
  unlike.mockReset();
  save.mockReset();
  unsave.mockReset();
});

describe("useFeed", () => {
  it("syncPost replaces the rendered item with the server copy", async () => {
    const stale = post("p1");
    feed.mockResolvedValue({ items: [stale, post("p2")], next_cursor: null });
    // The modal liked + commented: server state moved on without the list.
    get.mockResolvedValue(
      post("p1", { liked: true, like_count: 4, comment_count: 2 }),
    );

    const { result } = renderHook(() => useFeed("feed"));
    await waitFor(() => expect(result.current.loading).toBe(false));
    await act(() => result.current.syncPost("p1"));

    const synced = result.current.posts.find((p) => p.id === "p1")!;
    expect(synced.liked).toBe(true);
    expect(synced.like_count).toBe(4);
    expect(synced.comment_count).toBe(2);
    // untouched siblings keep their identity
    expect(result.current.posts.map((p) => p.id)).toEqual(["p1", "p2"]);
  });

  it("syncPost keeps the rendered item when the refetch fails", async () => {
    feed.mockResolvedValue({ items: [post("p1")], next_cursor: null });
    get.mockRejectedValue(new Error("offline"));

    const { result } = renderHook(() => useFeed("feed"));
    await waitFor(() => expect(result.current.loading).toBe(false));
    await act(() => result.current.syncPost("p1"));

    expect(result.current.posts).toHaveLength(1);
    expect(result.current.posts[0].like_count).toBe(3);
  });

  it("toggleLike is optimistic and rolls back on failure (MI-18)", async () => {
    const p = post("p1");
    feed.mockResolvedValue({ items: [p], next_cursor: null });
    like.mockRejectedValue(new Error("boom"));

    const { result } = renderHook(() => useFeed("feed"));
    await waitFor(() => expect(result.current.loading).toBe(false));
    await expect(
      act(() => result.current.toggleLike(result.current.posts[0])),
    ).rejects.toThrow("like_failed");

    expect(result.current.posts[0].liked).toBe(false);
    expect(result.current.posts[0].like_count).toBe(3);
  });
});
