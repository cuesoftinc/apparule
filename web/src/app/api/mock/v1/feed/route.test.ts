// Route-handler contract: envelope shapes + pagination over the mock store.
import { beforeEach, describe, expect, it } from "vitest";
import { resetStore } from "@/mocks/store";
import { GET as getFeed } from "./route";
import { GET as getPost } from "../posts/[id]/route";

beforeEach(() => {
  resetStore();
});

describe("GET /api/mock/v1/feed", () => {
  it("returns a cursor page of posts for the signed-in test user", async () => {
    const res = await getFeed(new Request("http://test/api/mock/v1/feed"));
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(Array.isArray(body.items)).toBe(true);
    expect(body.items.length).toBeGreaterThan(0);
    expect(body).toHaveProperty("next_cursor");
  });

  it("paginates with ?limit and next_cursor", async () => {
    const res1 = await getFeed(
      new Request("http://test/api/mock/v1/feed?limit=2"),
    );
    const page1 = await res1.json();
    expect(page1.items).toHaveLength(2);
    expect(page1.next_cursor).not.toBeNull();

    const res2 = await getFeed(
      new Request(
        `http://test/api/mock/v1/feed?limit=2&cursor=${page1.next_cursor}`,
      ),
    );
    const page2 = await res2.json();
    expect(page2.items[0].id).not.toBe(page1.items[0].id);
  });
});

describe("error envelope", () => {
  it("returns the snake_case envelope for unknown resources", async () => {
    const res = await getPost(
      new Request("http://test/api/mock/v1/posts/nope"),
      { params: Promise.resolve({ id: "nope" }) },
    );
    expect(res.status).toBe(404);
    const body = await res.json();
    expect(body.error.code).toBe("not_found");
    expect(typeof body.error.message).toBe("string");
  });
});
