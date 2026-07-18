// Freshness bands per MI-11: gradient <30d, amber 30–90d, gray >90d.
import { describe, expect, it } from "vitest";
import { freshnessOf } from "./measurement";

const now = new Date("2026-07-18T12:00:00Z");

function ago(days: number): string {
  return new Date(now.getTime() - days * 24 * 60 * 60 * 1000).toISOString();
}

describe("freshnessOf (MI-11 bands)", () => {
  it("is fresh under 30 days", () => {
    expect(freshnessOf(ago(0), now)).toBe("fresh");
    expect(freshnessOf(ago(12), now)).toBe("fresh");
    expect(freshnessOf(ago(29.9), now)).toBe("fresh");
  });

  it("is aging between 30 and 90 days", () => {
    expect(freshnessOf(ago(30), now)).toBe("aging");
    expect(freshnessOf(ago(58), now)).toBe("aging");
    expect(freshnessOf(ago(90), now)).toBe("aging");
  });

  it("is stale past 90 days", () => {
    expect(freshnessOf(ago(90.1), now)).toBe("stale");
    expect(freshnessOf(ago(140), now)).toBe("stale");
  });
});
