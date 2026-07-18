// Order state machine — must mirror order-lifecycle.md §1 exactly.
import { describe, expect, it } from "vitest";
import { canTransition, ORDER_STATUSES, ORDER_TRANSITIONS } from "./order";

describe("order state machine (order-lifecycle.md §1)", () => {
  it("covers all ten states", () => {
    expect(ORDER_STATUSES).toHaveLength(10);
    for (const s of ORDER_STATUSES) {
      expect(ORDER_TRANSITIONS[s]).toBeDefined();
    }
  });

  it("allows the happy path requested → … → delivered", () => {
    expect(canTransition("requested", "quoted")).toBe(true);
    expect(canTransition("quoted", "paid")).toBe(true);
    expect(canTransition("paid", "in_progress")).toBe(true);
    expect(canTransition("in_progress", "shipped")).toBe(true);
    expect(canTransition("shipped", "delivered")).toBe(true);
  });

  it("allows decline/cancel/refund/dispute edges", () => {
    expect(canTransition("requested", "declined")).toBe(true);
    expect(canTransition("requested", "cancelled")).toBe(true);
    expect(canTransition("quoted", "cancelled")).toBe(true);
    expect(canTransition("paid", "refunded")).toBe(true);
    expect(canTransition("paid", "disputed")).toBe(true);
    expect(canTransition("in_progress", "disputed")).toBe(true);
    expect(canTransition("shipped", "disputed")).toBe(true);
    expect(canTransition("disputed", "delivered")).toBe(true);
    expect(canTransition("disputed", "refunded")).toBe(true);
  });

  it("terminal states have no outgoing edges", () => {
    for (const terminal of ["delivered", "refunded", "declined", "cancelled"] as const) {
      expect(ORDER_TRANSITIONS[terminal]).toHaveLength(0);
    }
  });

  it("rejects illegal shortcuts", () => {
    expect(canTransition("requested", "paid")).toBe(false);
    expect(canTransition("quoted", "in_progress")).toBe(false);
    expect(canTransition("delivered", "disputed")).toBe(false);
    expect(canTransition("paid", "delivered")).toBe(false);
  });
});
