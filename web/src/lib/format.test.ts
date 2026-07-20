import { describe, expect, it } from "vitest";
import {
  formatAgo,
  formatAgoLong,
  formatAgoPhrase,
  formatCm,
  formatNaira,
} from "./format";

describe("format utilities", () => {
  it("formats kobo to naira", () => {
    expect(formatNaira(4_500_000)).toBe("₦45,000");
    expect(formatNaira(6_200_000)).toBe("₦62,000");
    expect(formatNaira(-620_000)).toBe("−₦6,200");
  });

  it("formats centimetres and inches at one decimal (master: '58.0 cm')", () => {
    expect(formatCm(42.5)).toBe("42.5 cm");
    expect(formatCm(42)).toBe("42.0 cm");
    expect(formatCm(50.8, "in")).toBe("20.0 in");
  });

  it("formats relative ages", () => {
    const now = new Date("2026-07-18T12:00:00Z");
    expect(formatAgo("2026-07-18T11:00:00Z", now)).toBe("1h");
    expect(formatAgo("2026-07-16T12:00:00Z", now)).toBe("2d");
    expect(formatAgo("2026-07-04T12:00:00Z", now)).toBe("2w");
  });

  it("long form for the PostCard timestamp (master: '2 HOURS AGO')", () => {
    const now = new Date("2026-07-18T12:00:00Z");
    expect(formatAgoLong("2026-07-18T11:30:00Z", now)).toBe("just now");
    expect(formatAgoLong("2026-07-18T10:00:00Z", now)).toBe("2 hours ago");
    expect(formatAgoLong("2026-07-17T12:00:00Z", now)).toBe("1 day ago");
    expect(formatAgoLong("2026-07-04T12:00:00Z", now)).toBe("2 weeks ago");
    // ≥30d switches to the absolute date like formatAgo
    expect(formatAgoLong("2026-05-22T12:00:00Z", now)).toMatch(/May/);
  });

  it("phrases relative ages for prose meta lines (system QA: no '22 May ago')", () => {
    const now = new Date("2026-07-18T12:00:00Z");
    expect(formatAgoPhrase("2026-07-18T11:59:59Z", now)).toBe("just now");
    expect(formatAgoPhrase("2026-07-16T12:00:00Z", now)).toBe("2d ago");
    expect(formatAgoPhrase("2026-07-04T12:00:00Z", now)).toBe("2w ago");
    // ≥30d switches to an absolute date — prefixed, never suffixed with "ago"
    expect(formatAgoPhrase("2026-05-22T12:00:00Z", now)).toBe("on 22 May");
    expect(formatAgoPhrase("2026-05-22T12:00:00Z", now)).not.toMatch(/ago/);
  });
});
