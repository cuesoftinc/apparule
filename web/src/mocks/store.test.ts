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
    // post-asooke-set has no seeded OPEN order (its APR-1058 is terminal), so
    // the duplicate-open-request guard stays out of the way.
    const created = store.createRequest("kiki.adeyemi", "post-asooke-set", {
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

    const quoted = store.quote(created.id, "maisonbisi", 5_500_000, "2026-08-10");
    expect(quoted.status).toBe("quoted");

    const paid = store.pay(created.id, "kiki.adeyemi");
    expect(paid.status).toBe("paid");
    expect(paid.payment?.state).toBe("held");
    expect(paid.payment?.platform_fee_cents).toBe(550_000); // 10%

    store.setStatus(created.id, "maisonbisi", "in_progress");
    store.setStatus(created.id, "maisonbisi", "shipped", "TRK-1");
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
    store.createRequest("kiki.adeyemi", "post-chromat-look", {
      session_id: "sess-recent-scan",
      delivery,
    });
    expect(() =>
      store.createRequest("kiki.adeyemi", "post-chromat-look", {
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

// ---------------------------------------------------------------------------
// W3 surface — full-state seed, profiles/social lists, capture, payouts,
// moderation gate, thread auto-reply (web-implementation.md §6 narrative).
// ---------------------------------------------------------------------------

describe("W3 seed — all ten order states render from boot", () => {
  it("seeds at least one order per lifecycle state for kiki", () => {
    const statuses = new Set(
      store.ordersFor("kiki.adeyemi", "customer").map((o) => o.status),
    );
    for (const s of [
      "requested", "quoted", "paid", "in_progress", "shipped",
      "delivered", "refunded", "declined", "disputed", "cancelled",
    ]) {
      expect(statuses.has(s as never), `missing seeded state ${s}`).toBe(true);
    }
  });

  it("seeds notifications of every kind", () => {
    const kinds = new Set([
      ...store.notificationsFor("kiki.adeyemi").map((n) => n.kind),
      ...store.notificationsFor("maisonbisi").map((n) => n.kind),
      ...store.notificationsFor("tunde.o").map((n) => n.kind),
    ]);
    for (const k of ["like", "follow", "comment", "quote", "status_change", "payout"]) {
      expect(kinds.has(k as never), `missing notification kind ${k}`).toBe(true);
    }
  });
});

describe("profiles & social lists", () => {
  it("resolves designer and regular-user profiles with viewer state", () => {
    const amara = store.profileFor("amara.designs", "kiki.adeyemi");
    expect(amara.kind).toBe("designer");
    if (amara.kind === "designer") {
      expect(amara.viewer_follows).toBe(true);
      expect(amara.viewer_is_self).toBe(false);
    }
    const kiki = store.profileFor("kiki.adeyemi", "kiki.adeyemi");
    expect(kiki.kind).toBe("user");
    expect(kiki.viewer_is_self).toBe(true);
  });

  it("followers/following/suggested project UserRow summaries", () => {
    const followers = store.followersOf("amara.designs", "kiki.adeyemi");
    expect(followers.map((f) => f.username)).toContain("kiki.adeyemi");
    const following = store.followingOf("amara.designs", "kiki.adeyemi");
    expect(following.map((f) => f.username)).toEqual(
      expect.arrayContaining(["tunde.o", "maisonbisi"]),
    );
    // tunde is the seeded suggestion (not followed by kiki)
    expect(
      store.suggestedDesigners("kiki.adeyemi").map((d) => d.username),
    ).toEqual(["tunde.o"]);
  });

  it("saved posts round-trip through engagement", () => {
    store.setEngagement("post-agbada", "kiki.adeyemi", "save", true);
    expect(store.savedPosts("kiki.adeyemi").map((p) => p.id)).toContain(
      "post-agbada",
    );
  });
});

describe("capture path (webcam, B4)", () => {
  it("QC fixture file names reproduce 422 codes with guidance", () => {
    expect(() =>
      store.createCaptureSession("kiki.adeyemi", {
        input_height_cm: 168,
        filename: "fixture-blurry.jpg",
      }),
    ).toThrowError(expect.objectContaining({ code: "blurry", status: 422 }));
  });

  it("upload → pending_save → save flips complete; retake deletes", () => {
    const session = store.createCaptureSession("kiki.adeyemi", {
      input_height_cm: 168,
      filename: "photo.jpg",
    });
    expect(session.status).toBe("pending_save");
    expect(session.measurements.some((m) => (m.confidence ?? 1) < 0.7)).toBe(
      true,
    );
    const saved = store.saveSession(session.id, "kiki.adeyemi");
    expect(saved.status).toBe("complete");
    // double-save is an invalid transition
    expect(() => store.saveSession(session.id, "kiki.adeyemi")).toThrowError(
      expect.objectContaining({ code: "invalid_transition" }),
    );
  });
});

describe("designer KYC gate + payout scripting", () => {
  it("pre-KYC designers can post but their posts serve post_unavailable", () => {
    store.enableDesigner("kiki.adeyemi", "Kiki Studio");
    const post = store.createPost("kiki.adeyemi", {
      caption: "First look",
      style_tags: ["test"],
      base_price_cents: null,
      turnaround_days: 7,
      media: [{ url: "/demo/outfit-w00.jpg", alt_text: "Look" }],
    });
    expect(post.id).toBeTruthy();
    expect(() =>
      store.createRequest("tunde.o", post.id, {
        session_id: "sess-recent-scan",
        delivery: {
          recipient_name: "T", phone: "1", line1: "x",
          city: "Lagos", state: "Lagos", country: "NG",
        },
      }),
    ).toThrowError(expect.objectContaining({ code: "post_unavailable", status: 409 }));
  });

  it("scripts Paystack resolution: resolved name / mismatch / lapse", () => {
    store.enableDesigner("kiki.adeyemi", "Kiki Studio");
    const resolved = store.resolveBank("kiki.adeyemi", "058", "0123456789");
    expect(resolved.account_name).toBe("KIKI ADEYEMI");
    expect(() =>
      store.resolveBank("kiki.adeyemi", "058", "0012345678"),
    ).toThrowError(expect.objectContaining({ code: "bank_resolution_failed" }));
    const lapsed = store.attachPayoutAccount("kiki.adeyemi", "058", "9999999999");
    expect(lapsed.kyc_state).toBe("lapsed");
    const verified = store.attachPayoutAccount("kiki.adeyemi", "058", "0123456789");
    expect(verified.kyc_state).toBe("verified");
    expect(store.me("kiki.adeyemi").designer.kyc_complete).toBe(true);
  });

  it("allows requote while quoted without a transition", () => {
    const requoted = store.quote("req-apr-1033", "amara.designs", 4_200_000, "2026-08-15");
    expect(requoted.status).toBe("quoted");
    expect(requoted.quote_cents).toBe(4_200_000);
  });

  it("customer cancel is legal from requested/quoted only", () => {
    expect(store.cancel("req-apr-1031", "kiki.adeyemi").status).toBe("cancelled");
    expect(() => store.cancel("req-apr-1042", "kiki.adeyemi")).toThrowError(
      expect.objectContaining({ code: "invalid_transition" }),
    );
  });
});

describe("notification prefs + moderation gate + thread auto-reply", () => {
  it("drops notifications the recipient's prefs disable", () => {
    store.updateMe("kiki.adeyemi", { notification_prefs: { quotes: false } });
    const before = store.notificationsFor("kiki.adeyemi").length;
    store.quote("req-apr-1031", "tunde.o", 6_000_000, "2026-08-20");
    expect(store.notificationsFor("kiki.adeyemi").length).toBe(before);
  });

  it("moderation queue is staff-only (kiki yes, tunde no)", () => {
    expect(store.moderationQueue("kiki.adeyemi").length).toBeGreaterThan(0);
    expect(() => store.moderationQueue("tunde.o")).toThrowError(
      expect.objectContaining({ code: "forbidden", status: 403 }),
    );
  });

  it("scripts one counterparty auto-reply per thread (MI-17)", () => {
    const before = store.messagesFor("req-apr-1042", "kiki.adeyemi").length;
    store.addMessage("req-apr-1042", "kiki.adeyemi", "Any progress?", null);
    const after = store.messagesFor("req-apr-1042", "kiki.adeyemi");
    expect(after.length).toBe(before + 2); // sent + scripted reply
    expect(after[after.length - 1].author_id).toBe("des-amara");
    store.addMessage("req-apr-1042", "kiki.adeyemi", "Hello again", null);
    expect(store.messagesFor("req-apr-1042", "kiki.adeyemi").length).toBe(
      before + 3, // no second auto-reply
    );
  });

  it("exports data + flags deletion_pending", () => {
    const exported = store.exportData("kiki.adeyemi");
    expect(exported.sessions).toBeTruthy();
    expect(store.requestDeletion("kiki.adeyemi").deletion_state).toBe(
      "deletion_pending",
    );
  });
});
