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
    const shoulder = newest.measurements.find(
      (m) => m.name === "shoulder_width",
    );
    expect(shoulder?.value_cm).toBe(42.5);
  });

  it("boot vault carries a low-confidence (<0.7) measurement — the B4 chip is reachable from seed (audit 2026-07-20)", () => {
    const sessions = store.sessionsFor("kiki.adeyemi");
    const newest = sessions[0];
    expect(
      newest.measurements.some(
        (m) => m.confidence !== null && m.confidence < 0.7,
      ),
    ).toBe(true);
  });

  it("designer posts_count matches the actually seeded posts (system QA)", () => {
    for (const designer of store.designers) {
      const actual = store.posts.filter(
        (p) => p.designer.username === designer.username,
      ).length;
      expect(designer.posts_count, designer.username).toBe(actual);
    }
  });

  it("seeded comment counts equal the seeded comment lists (P1 realism)", () => {
    for (const post of store.explore("kiki.adeyemi")) {
      expect(store.commentsFor(post.id).length, post.id).toBe(
        post.comment_count,
      );
    }
  });

  it("designer follower counts mirror the follow graph (P1 realism)", () => {
    for (const designer of store.designers) {
      expect(designer.followers_count, designer.username).toBe(
        store.followersOf(designer.username, "kiki.adeyemi").length,
      );
    }
  });

  it("#APR-1058 (child outfit gift) freezes child-scale manual measurements", () => {
    // PR #102 review: the "Little senator" order must not carry kiki's
    // adult vault snapshot — it's a gift with tape-measured child values
    // entered by hand at request time.
    const order = store.order("req-apr-1058", "kiki.adeyemi");
    expect(order.snapshot.values.method).toBe("manual");
    for (const m of order.snapshot.values.measurements) {
      expect(m.value_cm, m.name).toBeLessThan(70);
    }
    expect(order.notes).toMatch(/nephew/i);
    // kiki's own vault stays adult — the child session was deleted after
    // the snapshot froze (sessions are deletable; snapshots are immutable).
    const newest = store.sessionsFor("kiki.adeyemi")[0];
    expect(
      newest.measurements.find((m) => m.name === "shoulder_width")?.value_cm,
    ).toBe(42.5);
  });

  it("#APR-1042 (ankara maxi skirt) carries a skirt-appropriate note", () => {
    // PR #102 review: the recaptioned skirt order asked for "longer sleeves".
    const order = store.order("req-apr-1042", "kiki.adeyemi");
    expect(order.notes).toMatch(/ankle length/i);
    expect(order.notes).not.toMatch(/sleeve/i);
  });

  it("order snapshots are measured before the order exists (P1 realism)", () => {
    for (const order of store.orders) {
      const measured = new Date(order.snapshot.values.measured_at).getTime();
      const created = new Date(order.created_at).getTime();
      expect(measured, order.id).toBeLessThanOrEqual(created);
    }
  });

  it("order events read as real days of back-and-forth (PR #102 cadence)", () => {
    // The synthetic failure class: every event stamped with the boot
    // minute (an entire timeline at "15:51"). Each order's events must be
    // strictly ordered, never in the future, and a multi-event timeline
    // never collapses onto one wall-clock minute.
    const wallMinute = (iso: string) => {
      const d = new Date(iso);
      return `${d.getHours()}:${d.getMinutes()}`;
    };
    for (const order of store.orders) {
      const times = order.events.map((e) => new Date(e.created_at).getTime());
      for (let i = 1; i < times.length; i++) {
        expect(times[i], `${order.id} event ${i}`).toBeGreaterThan(
          times[i - 1],
        );
      }
      expect(Math.max(...times), order.id).toBeLessThanOrEqual(Date.now());
      if (order.events.length > 1) {
        const minutes = new Set(
          order.events.map((e) => wallMinute(e.created_at)),
        );
        expect(minutes.size, order.id).toBeGreaterThan(1);
      }
      // One coherent record: the order (and its frozen snapshot) exists
      // from the requested event, not from a separately-stamped boot time.
      expect(order.created_at, order.id).toBe(order.events[0].created_at);
      expect(order.snapshot.created_at, order.id).toBe(order.created_at);
    }
  });

  it("thread messages follow the same cadence rule per thread (PR #102)", () => {
    const wallMinute = (iso: string) => {
      const d = new Date(iso);
      return `${d.getHours()}:${d.getMinutes()}`;
    };
    const byThread = new Map<string, typeof store.messages>();
    for (const message of store.messages) {
      const list = byThread.get(message.request_id) ?? [];
      list.push(message);
      byThread.set(message.request_id, list);
    }
    for (const [requestId, messages] of byThread) {
      const times = messages.map((m) => new Date(m.created_at).getTime());
      for (let i = 1; i < times.length; i++) {
        expect(times[i], `${requestId} message ${i}`).toBeGreaterThan(
          times[i - 1],
        );
      }
      expect(Math.max(...times), requestId).toBeLessThanOrEqual(Date.now());
      if (messages.length > 1) {
        const minutes = new Set(messages.map((m) => wallMinute(m.created_at)));
        expect(minutes.size, requestId).toBeGreaterThan(1);
      }
    }
  });

  it("suggested designers carry real photo avatars from the licensed pool", () => {
    // Audit 2026-07-20: initials-only suggestion rows read as broken next
    // to the canvas narrative. Each suggested designer fronts their own
    // published photography — counts and identities stay honest.
    const rows = store.suggestedDesigners("kiki.adeyemi");
    expect(rows.length).toBeGreaterThan(0);
    for (const row of rows) {
      expect(row.avatar_url, row.username).toMatch(
        /^\/demo\/outfit-w\d+\.jpg$/,
      );
    }
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
    ).toThrow(
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

    const quoted = store.quote(
      created.id,
      "maisonbisi",
      5_500_000,
      "2026-08-10",
    );
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
    store.createRequest("kiki.adeyemi", "post-evening-gown", {
      session_id: "sess-recent-scan",
      delivery,
    });
    expect(() =>
      store.createRequest("kiki.adeyemi", "post-evening-gown", {
        session_id: "sess-recent-scan",
        delivery,
      }),
    ).toThrow(expect.objectContaining({ code: "duplicate_request" }));
  });

  it("order detail is party-only (strangers get not_found)", () => {
    expect(() => store.order("req-apr-1042", "tunde.o")).toThrow(
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
    expect(store.post("post-ankara-gown", "kiki.adeyemi").like_count).toBe(
      before,
    );
  });

  it("rejects over-length comments", () => {
    expect(() =>
      store.addComment("post-ankara-gown", "kiki.adeyemi", "x".repeat(501)),
    ).toThrow(expect.objectContaining({ code: "validation_failed" }));
  });

  it("explore price bands follow the decided defaults", () => {
    const budget = store.explore(
      "kiki.adeyemi",
      undefined,
      undefined,
      "budget",
    );
    // ₦22,000 shirt is the only sub-25k priced post
    expect(budget.map((p) => p.id)).toEqual(["post-print-brothers"]);
    // the ₦150,000 bridal gown demos the premium band (P1 realism)
    const premium = store.explore(
      "kiki.adeyemi",
      undefined,
      undefined,
      "premium",
    );
    expect(premium.map((p) => p.id)).toEqual(["post-bridal-gown"]);
  });

  it("explore max_turnaround_days keeps only posts deliverable in time", () => {
    const week = store.explore(
      "kiki.adeyemi",
      undefined,
      undefined,
      undefined,
      7,
    );
    expect(week.map((p) => p.id)).toEqual([
      "post-print-brothers",
      "post-dance-troupe",
    ]);
    for (const p of week) expect(p.turnaround_days).toBeLessThanOrEqual(7);
  });

  it("explore near_me proximity-ranks by designer location — no hard gate", () => {
    // Default recency order leads with the newest post: the Abuja atelier.
    const recency = store.explore("kiki.adeyemi");
    expect(recency[0].id).toBe("post-atelier-abuja");
    // near_me for Lagos-based kiki: every Lagos designer's post ranks above
    // the Abuja designer's, which still APPEARS (ranking, not filtering).
    const near = store.explore(
      "kiki.adeyemi",
      undefined,
      undefined,
      undefined,
      undefined,
      true,
    );
    expect(near).toHaveLength(recency.length);
    expect(near[0].id).toBe("post-print-couple"); // newest Lagos post
    expect(near[near.length - 1].id).toBe("post-atelier-abuja");
  });

  it("explore near_me ranks against the designer's CURRENT profile location", () => {
    // PR #103 review: settings B7 writes Account.profile_location — the
    // cached DesignerProfile.location must follow, or near-me keeps
    // ranking on stale onboarding data.
    store.updateMe("eniola.stitches", {
      profile_location: { city: "Lagos", state: "Lagos", country: "NG" },
    });
    const near = store.explore(
      "kiki.adeyemi",
      undefined,
      undefined,
      undefined,
      undefined,
      true,
    );
    // her newest-overall post now leads the same-city tier
    expect(near[0].id).toBe("post-atelier-abuja");
  });

  it("explore near_me requires country equality before city/state tiers (PR #103)", () => {
    // Same city/state TEXT in a different country must not outrank a
    // same-country designer — free-text names repeat across borders.
    store.updateMe("eniola.stitches", {
      profile_location: { city: "Lagos", state: "Lagos", country: "GH" },
    });
    const near = store.explore(
      "kiki.adeyemi",
      undefined,
      undefined,
      undefined,
      undefined,
      true,
    );
    // her newest-overall post still ranks LAST despite the matching text
    expect(near[near.length - 1].id).toBe("post-atelier-abuja");
  });

  it("explore near_me is a no-op for callers without a profile location", () => {
    store.updateMe("kiki.adeyemi", { profile_location: null });
    const near = store.explore(
      "kiki.adeyemi",
      undefined,
      undefined,
      undefined,
      undefined,
      true,
    );
    expect(near[0].id).toBe("post-atelier-abuja"); // recency order holds
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
    expect(() => store.earnings("kiki.adeyemi")).toThrow(
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
    expect(() => store.idempotent("k2", "b", () => 2)).toThrow(
      expect.objectContaining({ code: "idempotency_conflict", status: 409 }),
    );
  });
});

describe("profile", () => {
  it("rejects taken usernames with name_taken", () => {
    expect(() =>
      store.updateMe("kiki.adeyemi", { username: "maisonbisi" }),
    ).toThrow(expect.objectContaining({ code: "name_taken", status: 409 }));
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
      "requested",
      "quoted",
      "paid",
      "in_progress",
      "shipped",
      "delivered",
      "refunded",
      "declined",
      "disputed",
      "cancelled",
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
    for (const k of [
      "like",
      "follow",
      "comment",
      "quote",
      "status_change",
      "payout",
    ]) {
      expect(kinds.has(k as never), `missing notification kind ${k}`).toBe(
        true,
      );
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
    // tunde + the Abuja atelier are the seeded suggestions (not followed)
    expect(
      store.suggestedDesigners("kiki.adeyemi").map((d) => d.username),
    ).toEqual(["tunde.o", "eniola.stitches"]);
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
    ).toThrow(expect.objectContaining({ code: "blurry", status: 422 }));
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
    expect(() => store.saveSession(session.id, "kiki.adeyemi")).toThrow(
      expect.objectContaining({ code: "invalid_transition" }),
    );
  });
});

describe("ranked pagination (api.md §5 — snapshot cursors)", () => {
  const feedPage = (
    cursor: string | null,
    limit: number,
    actor = "kiki.adeyemi",
    fingerprint = "feed",
  ) =>
    store.rankedPage(
      actor,
      fingerprint,
      () => store.feed(actor),
      cursor,
      limit,
    );

  it("freezes the rank per scroll session — no duplicates or skips mid-scroll", () => {
    const page1 = feedPage(null, 4);
    expect(page1.items).toHaveLength(4);
    expect(page1.next_cursor).not.toBeNull();
    // A followed designer publishes mid-scroll — a fresh rank would lead
    // with it and shift every offset (PR #103 review).
    const fresh = store.createPost("amara.designs", {
      caption: "Mid-scroll drop",
      style_tags: ["ankara"],
      base_price_cents: null,
      turnaround_days: 7,
      media: [{ url: "/demo/outfit-w14.jpg", alt_text: "Fabric drop" }],
    });
    const page2 = feedPage(page1.next_cursor, 4);
    const ids = [...page1.items, ...page2.items].map((p) => p.id);
    expect(new Set(ids).size).toBe(ids.length); // never duplicates
    expect(ids).not.toContain(fresh.id); // new posts land on refresh only
    expect(page2.next_cursor).toBeNull();
    // …and a NEW scroll session (no cursor) does lead with it
    expect(feedPage(null, 4).items[0].id).toBe(fresh.id);
  });

  it("posts deleted mid-scroll drop out without duplicating", () => {
    const page1 = feedPage(null, 2);
    store.deletePost("post-asooke-set", "maisonbisi"); // would be page 2
    const page2 = feedPage(page1.next_cursor, 2);
    const ids = [...page1.items, ...page2.items].map((p) => p.id);
    expect(ids).not.toContain("post-asooke-set");
    expect(new Set(ids).size).toBe(ids.length);
  });

  it("freezes only the RANK — engagement state stays live", () => {
    const page1 = feedPage(null, 4);
    store.setEngagement("post-fabric-drop", "kiki.adeyemi", "like", true);
    const page2 = feedPage(page1.next_cursor, 4);
    expect(page2.items.find((p) => p.id === "post-fabric-drop")?.liked).toBe(
      true,
    );
  });

  it("expired or garbled cursors start a fresh scroll session", () => {
    const garbled = feedPage(
      Buffer.from("rank-nope:4", "utf8").toString("base64url"),
      4,
    );
    expect(garbled.items).toHaveLength(4);
    expect(garbled.items[0].id).toBe(store.feed("kiki.adeyemi")[0].id);
  });

  it("cursors are bound to their actor + query — cross-use starts fresh (PR #103)", () => {
    const page1 = feedPage(null, 2);
    const cursor = page1.next_cursor!;
    // Same cursor presented against another endpoint/filter fingerprint:
    // not honored — a fresh explore snapshot starts at offset 0.
    const crossQuery = store.rankedPage(
      "kiki.adeyemi",
      "explore|||||",
      () => store.explore("kiki.adeyemi"),
      cursor,
      2,
    );
    expect(crossQuery.items[0].id).toBe(store.explore("kiki.adeyemi")[0].id);
    // Same cursor replayed by ANOTHER actor: not honored either — tunde
    // gets his own feed's first page, not kiki's snapshot offsets.
    const crossActor = feedPage(cursor, 2, "tunde.o");
    expect(crossActor.items[0].id).toBe(store.feed("tunde.o")[0].id);
    // …while the minting actor's cursor still resolves its snapshot.
    const page2 = feedPage(cursor, 2);
    const ids = [...page1.items, ...page2.items].map((p) => p.id);
    expect(new Set(ids).size).toBe(ids.length);
  });

  it("active snapshots survive heavy first-page traffic (no FIFO eviction)", () => {
    const page1 = feedPage(null, 2);
    // 150 other scroll sessions begin before this cursor is consumed —
    // size-based eviction used to invalidate it (PR #103 review).
    for (let i = 0; i < 150; i++) feedPage(null, 2, "tunde.o");
    const page2 = feedPage(page1.next_cursor, 2);
    const ids = [...page1.items, ...page2.items].map((p) => p.id);
    expect(new Set(ids).size).toBe(ids.length); // continued, not restarted
    expect(ids).toHaveLength(4);
  });
});

describe("session exports (F2-9 / PLAT-004)", () => {
  it("csv export inlines a header + one row per measurement", () => {
    const { url, format } = store.sessionExport(
      "sess-manual-tape",
      "kiki.adeyemi",
      "csv",
    );
    expect(format).toBe("csv");
    expect(url).toMatch(/^data:text\/csv;base64,/);
    const body = Buffer.from(url.split(",")[1], "base64").toString("utf8");
    const lines = body.split("\n");
    expect(lines[0]).toBe("name,value_cm,source,confidence");
    expect(lines).toHaveLength(1 + 4); // header + the session's 4 values
    expect(body).toContain("shoulder_width,42,");
  });

  it("pdf export is a real PDF carrying the measurement lines", () => {
    const { url, format } = store.sessionExport(
      "sess-recent-scan",
      "kiki.adeyemi",
      "pdf",
    );
    expect(format).toBe("pdf");
    expect(url).toMatch(/^data:application\/pdf;base64,/);
    const body = Buffer.from(url.split(",")[1], "base64").toString("utf8");
    expect(body.startsWith("%PDF-1.4")).toBe(true);
    expect(body).toContain("shoulder_width: 42.5 cm");
    expect(body.trimEnd().endsWith("%%EOF")).toBe(true);
  });

  it("pdf export paginates large sessions — no rows fall off the page (PR #103)", () => {
    // Grow the session well past one page's 36 lines via append-only
    // corrections (the API accepts unbounded entries).
    store.appendCorrections(
      "sess-recent-scan",
      "kiki.adeyemi",
      Array.from({ length: 60 }, (_, i) => ({
        name: `correction_${i}`,
        value_cm: 40 + i / 10,
      })),
    );
    const { url } = store.sessionExport(
      "sess-recent-scan",
      "kiki.adeyemi",
      "pdf",
    );
    const body = Buffer.from(url.split(",")[1], "base64").toString("utf8");
    // 4 header lines + 62 measurements = 66 lines → 2 pages
    expect(body).toContain("/Count 2");
    // first and LAST rows are both present in the page streams
    expect(body).toContain("shoulder_width: 42.5 cm");
    expect(body).toContain("correction_59:");
  });

  it("exports are tenant-scoped: another user's session reads not_found", () => {
    expect(() =>
      store.sessionExport("sess-recent-scan", "tunde.o", "csv"),
    ).toThrow(expect.objectContaining({ code: "not_found", status: 404 }));
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
          recipient_name: "T",
          phone: "1",
          line1: "x",
          city: "Lagos",
          state: "Lagos",
          country: "NG",
        },
      }),
    ).toThrow(
      expect.objectContaining({ code: "post_unavailable", status: 409 }),
    );
  });

  it("scripts Paystack resolution: resolved name / mismatch / lapse", () => {
    store.enableDesigner("kiki.adeyemi", "Kiki Studio");
    const resolved = store.resolveBank("kiki.adeyemi", "058", "0123456789");
    expect(resolved.account_name).toBe("KIKI ADEYEMI");
    expect(() =>
      store.resolveBank("kiki.adeyemi", "058", "0012345678"),
    ).toThrow(expect.objectContaining({ code: "bank_resolution_failed" }));
    const lapsed = store.attachPayoutAccount(
      "kiki.adeyemi",
      "058",
      "9999999999",
    );
    expect(lapsed.kyc_state).toBe("lapsed");
    const verified = store.attachPayoutAccount(
      "kiki.adeyemi",
      "058",
      "0123456789",
    );
    expect(verified.kyc_state).toBe("verified");
    expect(store.me("kiki.adeyemi").designer.kyc_complete).toBe(true);
  });

  it("attach stores the bank display name, never the code (audit #10)", () => {
    store.enableDesigner("kiki.adeyemi", "Kiki Studio");
    const attached = store.attachPayoutAccount(
      "kiki.adeyemi",
      "058",
      "0123454521",
    );
    // Every payout surface (B8 verified, B9, settings) renders bank_name —
    // "GTBank ••• 4521", not "058 ••• 4521" (Figma 210:3 / 269:10345).
    expect(attached.bank_name).toBe("GTBank");
    expect(attached.account_last4).toBe("4521");
    expect(
      store.attachPayoutAccount("kiki.adeyemi", "033", "0123456789").bank_name,
    ).toBe("UBA");
  });

  it("allows requote while quoted without a transition", () => {
    const requoted = store.quote(
      "req-apr-1033",
      "amara.designs",
      4_200_000,
      "2026-08-15",
    );
    expect(requoted.status).toBe("quoted");
    expect(requoted.quote_cents).toBe(4_200_000);
  });

  it("customer cancel is legal from requested/quoted only", () => {
    expect(store.cancel("req-apr-1031", "kiki.adeyemi").status).toBe(
      "cancelled",
    );
    expect(() => store.cancel("req-apr-1042", "kiki.adeyemi")).toThrow(
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
    expect(() => store.moderationQueue("tunde.o")).toThrow(
      expect.objectContaining({ code: "forbidden", status: 403 }),
    );
  });

  it("queue seeds the canvas narrative: open rows lead, actioned audit row renders, dismissed drop", () => {
    const queue = store.moderationQueue("kiki.adeyemi");
    expect(queue.length).toBe(3);
    expect(queue.filter((r) => r.status === "open").length).toBe(2);
    // Open rows lead; the actioned exemplar (audit trail) trails.
    expect(queue[queue.length - 1].status).toBe("actioned");
    const actioned = queue[queue.length - 1];
    expect(actioned.actioned_by?.username).toBe("mod.sarah");
    expect(actioned.action).toBe("hide_post");
    expect(actioned.actioned_at).toBeTruthy();
    // The reported-post row carries its author + thumb (canvas anatomy).
    const postReport = queue.find((r) => r.subject_kind === "post")!;
    expect(postReport.subject_preview.author_username).toBe("amara.designs");
    expect(postReport.subject_preview.thumb_url).toMatch(/^\/demo\//);
    // Acting writes the audit fields; dismissing removes the row.
    const acted = store.actOnReport("rep-2", "kiki.adeyemi", "hide_post");
    expect(acted.actioned_by?.username).toBe("kiki.adeyemi");
    expect(acted.action).toBe("hide_post");
    store.actOnReport("rep-1", "kiki.adeyemi", "dismiss");
    const after = store.moderationQueue("kiki.adeyemi");
    expect(after.some((r) => r.id === "rep-1")).toBe(false);
    expect(after.find((r) => r.id === "rep-2")?.status).toBe("actioned");
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
