// GitHub stars controller — runtime count with graceful "Star" fallback
// (pages.md A1/A7b; accuracy standard: no invented counts).
import { beforeEach, describe, expect, it, vi } from "vitest";
import { renderHook, waitFor } from "@testing-library/react";

const stars = vi.fn<() => Promise<number | null>>();
vi.mock("@/models/repositories/github-repo", () => ({
  githubRepo: { stars: () => stars() },
}));

import { resetGithubStarsCache, useGithubStars } from "./use-github-stars";

beforeEach(() => {
  stars.mockReset();
  resetGithubStarsCache();
});

describe("useGithubStars", () => {
  it("resolves to the fetched count (count-up settles on the real value)", async () => {
    stars.mockResolvedValue(1234);
    const { result } = renderHook(() => useGithubStars());
    expect(result.current).toBeNull(); // neutral until the fetch lands
    // the 800ms count-up settles on the real value (jsdom rAF is slow)
    await waitFor(() => expect(result.current).toBe(1234), { timeout: 4000 });
  });

  it("stays null on failure — the badge keeps its neutral Star label", async () => {
    stars.mockResolvedValue(null);
    const { result } = renderHook(() => useGithubStars());
    await waitFor(() => expect(stars).toHaveBeenCalled());
    expect(result.current).toBeNull();
  });

  it("fetches once and shares the cache across subscribers", async () => {
    stars.mockResolvedValue(77);
    const { result: a } = renderHook(() => useGithubStars());
    const { result: b } = renderHook(() => useGithubStars());
    await waitFor(() => expect(a.current).toBe(77), { timeout: 4000 });
    await waitFor(() => expect(b.current).toBe(77), { timeout: 4000 });
    expect(stars).toHaveBeenCalledTimes(1);
  });
});
