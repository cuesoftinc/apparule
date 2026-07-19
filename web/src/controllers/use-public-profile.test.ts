// Public-profile controller — the post-modal sync seam (PR #103 review):
// modal mutations live in the modal's own usePost, so the profile grids
// re-sync the post (and the self-only saved grid) on modal close.
import { beforeEach, describe, expect, it, vi } from "vitest";
import { act, renderHook, waitFor } from "@testing-library/react";
import type { Post } from "@/models";

const profileGet = vi.fn();
const profilePosts = vi.fn();
const profileSaved = vi.fn();
vi.mock("@/models/repositories/profiles-repo", () => ({
  profilesRepo: {
    get: (...a: unknown[]) => profileGet(...a),
    posts: (...a: unknown[]) => profilePosts(...a),
    saved: (...a: unknown[]) => profileSaved(...a),
    followers: vi.fn(),
    following: vi.fn(),
  },
}));

const postGet = vi.fn();
vi.mock("@/models/repositories/posts-repo", () => ({
  postsRepo: {
    get: (...a: unknown[]) => postGet(...a),
    follow: vi.fn(),
    unfollow: vi.fn(),
  },
}));

import { usePublicProfile } from "./use-public-profile";

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
    style_tags: [],
    base_price_cents: null,
    currency: "NGN",
    turnaround_days: 14,
    media: [],
    like_count: 3,
    comment_count: 1,
    liked: false,
    saved: true,
    created_at: new Date().toISOString(),
    ...overrides,
  } as Post;
}

beforeEach(() => {
  profileGet.mockReset();
  profilePosts.mockReset();
  profileSaved.mockReset();
  postGet.mockReset();
});

describe("usePublicProfile.syncPost", () => {
  it("re-syncs the grid tile and refreshes the self saved grid on modal close", async () => {
    profileGet.mockResolvedValue({
      kind: "designer",
      designer: { username: "amara.designs" },
      viewer_follows: true,
      viewer_is_self: true,
    });
    profilePosts.mockResolvedValue({ items: [post("p1")], next_cursor: null });
    profileSaved.mockResolvedValueOnce({
      items: [post("p1")],
      next_cursor: null,
    });
    // In the modal: liked + commented + UNSAVED.
    postGet.mockResolvedValue(
      post("p1", { liked: true, like_count: 4, comment_count: 2, saved: false }),
    );
    profileSaved.mockResolvedValueOnce({ items: [], next_cursor: null });

    const { result } = renderHook(() => usePublicProfile("amara.designs"));
    await waitFor(() => expect(result.current.loading).toBe(false));
    expect(result.current.saved).toHaveLength(1);

    await act(() => result.current.syncPost("p1"));
    expect(result.current.posts[0].like_count).toBe(4);
    expect(result.current.posts[0].comment_count).toBe(2);
    // the unsaved tile leaves the saved grid without a manual reload
    expect(result.current.saved).toHaveLength(0);
  });

  it("keeps the rendered tiles when the refetch fails", async () => {
    profileGet.mockResolvedValue({
      kind: "designer",
      designer: { username: "amara.designs" },
      viewer_follows: false,
      viewer_is_self: false,
    });
    profilePosts.mockResolvedValue({ items: [post("p1")], next_cursor: null });
    postGet.mockRejectedValue(new Error("offline"));

    const { result } = renderHook(() => usePublicProfile("amara.designs"));
    await waitFor(() => expect(result.current.loading).toBe(false));
    await act(() => result.current.syncPost("p1"));
    expect(result.current.posts[0].like_count).toBe(3);
    expect(profileSaved).not.toHaveBeenCalled(); // not self — saved untouched
  });
});
