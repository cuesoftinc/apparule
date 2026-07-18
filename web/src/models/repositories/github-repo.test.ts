// GitHub repo — the only network call on the marketing surface; every
// failure path resolves to null (neutral badge, accuracy standard).
import { afterEach, describe, expect, it, vi } from "vitest";
import { githubRepo } from "./github-repo";

afterEach(() => {
  vi.unstubAllGlobals();
});

describe("githubRepo.stars", () => {
  it("returns stargazers_count on success", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue(
        new Response(JSON.stringify({ stargazers_count: 321 }), {
          status: 200,
        }),
      ),
    );
    await expect(githubRepo.stars()).resolves.toBe(321);
  });

  it("returns null on a non-OK response", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue(new Response("{}", { status: 403 })),
    );
    await expect(githubRepo.stars()).resolves.toBeNull();
  });

  it("returns null when the payload has no numeric count", async () => {
    vi.stubGlobal(
      "fetch",
      vi
        .fn()
        .mockResolvedValue(new Response(JSON.stringify({}), { status: 200 })),
    );
    await expect(githubRepo.stars()).resolves.toBeNull();
  });

  it("returns null on network failure", async () => {
    vi.stubGlobal("fetch", vi.fn().mockRejectedValue(new Error("offline")));
    await expect(githubRepo.stars()).resolves.toBeNull();
  });
});
