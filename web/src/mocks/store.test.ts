// Mock store — seed narrative integrity + lifecycle/engagement semantics.
import { beforeEach, describe, expect, it } from "vitest";
import { MockApiError } from "./http";
import { resetStore } from "./store";
import type { MockStore } from "./store";

let store: MockStore;

beforeEach(() => {
  store = resetStore();
});

describe("seed narrative", () => {
  it("seeds kiki + the three Lagos designers", () => {
    expect(store.me("kiki.adeyemi").display_name).toBe("Kiki Adeyemi");
    for (const d of ["amara.designs", "tunde.o", "maisonbisi"]) {
      const designer = store.designerByUsername(d);
      expect(designer?.location?.city).toBe("Lagos");
      expect(designer?.verified).toBe(true);
    }
  });

  it("seeds #APR-1042 ankara ₦45,000 in_progress with escrow held", () => {
    const order = store.order("req-apr-1042", "kiki.adeyemi");
    expect(order.order_number).toBe("APR-1042");
    expect(order.status).toBe("in_progress");
    expect(order.quote_cents).toBe(4_500_000);
    expect(order.designer.username).toBe("amara.designs");
    expect(order.payment?.state).toBe("held");
    expect(order.payment?.platform_fee_cents).toBe(450_000);
  });

  it("seeds #APR-1058 aso-oke ₦62,000 delivered and paid out", () => {
    const order = store.order("req-apr-1058", "kiki.adeyemi");
    expect(order.order_number).toBe("APR-1058");
    expect(order.status).toBe("delivered");
    expect(order.quote_cents).toBe(6_200_000);
    expect(order.designer.username).toBe("maisonbisi");
    expect(order.payment?.state).toBe("released");
  });

  it("seeds kiki's vault with a fresh 42.5 cm shoulder measurement", () => {
    const sessions = store.sessionsFor("kiki.adeyemi");
    expect(sessions.length).toBeGreaterThanOrEqual(3);
    const newest = sessions[0];
    const shoulder = newest.measurements.find((m) => m.name === "shoulder_width");
    expect(shoulder?.value_cm).toBe(42.5);
  });

  it("feed contains only followed designers (amara + bisi, not tunde)", () => {
    const feed = store.feed("kiki.adeyemi");
    expect(feed.length).toBeGreaterThan(0);
    const usernames = new Set(feed.map((p) => p.designer.username));
    expect(usernames.has("amara.designs")).toBe(true);
    expect(usernames.has("maisonbisi")).toBe(true);
    expect(usernames.has("tunde.o")).toBe(false);
  });

  it("every seeded post references a /demo/ photo", () => {
    for (const post of store.explore("kiki.adeyemi")) {
      for (const media of post.media) {
        expect(media.url).toMatch(/^\/demo\/outfit-w\d+\.jpg$/);
        expect(media.alt_text.length).toBeGreaterThan(0);
      }
    }
  });
});

describe("order lifecycle enforcement", () => {
  it("rejects illegal transitions with invalid_transition", () => {
    expect(() =>
      store.setStatus("req-apr-1058", "maisonbisi", "in_progress"),
    ).toThrowError(
      expect.objectContaining({ code: "invalid_transition", status: 409 }),
    );
  });

  it("walks a full commission: request → quote → pay → … → delivered", () => {
    const created = store.createRequest("kiki.adeyemi", "post-agbada", {
      session_id: "sess-recent-scan",
      notes: "For a wedding",
      delivery: {
        recipient_name: "Kiki Adeyemi",
        phone: "+2348012345678",
        line1: "14 Adeola Odeku St",
        city: "Lagos",
        state: "Lagos",
        country: "NG",
      },
    });
    expect(created.status).toBe("requested");
    // snapshot frozen from the chosen session
    expect(created.snapshot.values.measurements).toEqual(
      expect.arrayContaining([{ name: "shoulder_width", value_cm: 42.5 }]),
    );

    const quoted = store.quote(created.id, "tunde.o", 5_500_000, "2026-08-10");
    expect(quoted.status).toBe("quoted");

    const paid = store.pay(created.id, "kiki.adeyemi");
    expect(paid.status).toBe("paid");
    expect(paid.payment?.state).toBe("held");
    expect(paid.payment?.platform_fee_cents).toBe(550_000); // 10%

    store.setStatus(created.id, "tunde.o", "in_progress");
    store.setStatus(created.id, "tunde.o", "shipped", "TRK-1");
    const delivered = store.confirmDelivery(created.id, "kiki.adeyemi");
    expect(delivered.status).toBe("delivered");
    expect(delivered.payment?.state).toBe("released");
  });

  it("blocks duplicate open requests for the same post", () => {
    const delivery = {
      recipient_name: "K",
      phone: "1",
      line1: "x",
      city: "Lagos",
      state: "Lagos",
      country: "NG",
    };
    store.createRequest("kiki.adeyemi", "post-agbada", {
      session_id: "sess-recent-scan",
      delivery,
    });
    expect(() =>
      store.createRequest("kiki.adeyemi", "post-agbada", {
        session_id: "sess-recent-scan",
        delivery,
      }),
    ).toThrowError(expect.objectContaining({ code: "duplicate_request" }));
  });

  it("order detail is party-only (strangers get not_found)", () => {
    expect(() => store.order("req-apr-1042", "tunde.o")).toThrowError(
      expect.objectContaining({ code: "not_found", status: 404 }),
    );
  });
});

describe("engagement", () => {
  it("like toggle is idempotent and adjusts the count once", () => {
    const before = store.post("post-ankara-gown", "kiki.adeyemi").like_count;
    store.setEngagement("post-ankara-gown", "kiki.adeyemi", "like", true);
    store.setEngagement("post-ankara-gown", "kiki.adeyemi", "like", true);
    const after = store.post("post-ankara-gown", "kiki.adeyemi");
    expect(after.like_count).toBe(before + 1);
    expect(after.liked).toBe(true);
    store.setEngagement("post-ankara-gown", "kiki.adeyemi", "like", false);
    expect(store.post("post-ankara-gown", "kiki.adeyemi").like_count).toBe(before);
  });

  it("rejects over-length comments", () => {
    expect(() =>
      store.addComment("post-ankara-gown", "kiki.adeyemi", "x".repeat(501)),
    ).toThrowError(expect.objectContaining({ code: "validation_failed" }));
  });

  it("explore price bands follow the decided defaults", () => {
    const budget = store.explore("kiki.adeyemi", undefined, undefined, "budget");
    // ₦22,000 shirt is the only sub-25k priced post
    expect(budget.map((p) => p.id)).toEqual(["post-print-brothers"]);
  });
});

describe("earnings (designer view)", () => {
  it("computes maisonbisi's released balance net of the 10% fee", () => {
    const earnings = store.earnings("maisonbisi");
    expect(earnings.balance_cents).toBe(6_200_000 - 620_000);
    const kinds = earnings.transactions.map((t) => t.kind);
    expect(kinds).toContain("payout");
    expect(kinds).toContain("fee_line");
  });

  it("holds amara's escrow as pending until delivery", () => {
    const earnings = store.earnings("amara.designs");
    expect(earnings.pending_cents).toBe(4_500_000 - 450_000);
  });

  it("non-designers get a 403", () => {
    expect(() => store.earnings("kiki.adeyemi")).toThrowError(
      expect.objectContaining({ status: 403 }),
    );
  });
});

describe("idempotency (api.md §4)", () => {
  it("replays the original response for the same key + payload", () => {
    const first = store.idempotent("k1", "payload", () =>
      store.createManualSession("kiki.adeyemi", {
        input_height_cm: 168,
        measurements: [{ name: "shoulder_width", value_cm: 42.7 }],
      }),
    );
    const replay = store.idempotent("k1", "payload", () => {
      throw new Error("must not re-execute");
    });
    expect(replay).toEqual(first);
  });

  it("conflicts on the same key with a different payload", () => {
    store.idempotent("k2", "a", () => 1);
    expect(() => store.idempotent("k2", "b", () => 2)).toThrowError(
      expect.objectContaining({ code: "idempotency_conflict", status: 409 }),
    );
  });
});

describe("profile", () => {
  it("rejects taken usernames with name_taken", () => {
    expect(() =>
      store.updateMe("kiki.adeyemi", { username: "maisonbisi" }),
    ).toThrowError(expect.objectContaining({ code: "name_taken", status: 409 }));
  });

  it("errors are MockApiError instances (envelope-able)", () => {
    try {
      store.post("nope", "kiki.adeyemi");
      expect.unreachable();
    } catch (e) {
      expect(e).toBeInstanceOf(MockApiError);
    }
  });
});
