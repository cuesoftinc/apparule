import { describe, expect, it } from "vitest";
import {
  formatAgo,
  formatAgoPhrase,
  formatCm,
  formatDateTimeUtc,
  formatDateUtc,
  formatNaira,
  formatTimeUtc,
  isSameUtcDay,
} from "./format";

describe("format utilities", () => {
  it("formats kobo to naira", () => {
    expect(formatNaira(4_500_000)).toBe("₦45,000");
    expect(formatNaira(6_200_000)).toBe("₦62,000");
    expect(formatNaira(-620_000)).toBe("−₦6,200");
  });

  it("formats centimetres and inches — always one decimal (Figma '58.0 cm' idiom)", () => {
    expect(formatCm(42.5)).toBe("42.5 cm");
    expect(formatCm(42)).toBe("42.0 cm");
    expect(formatCm(92)).toBe("92.0 cm");
    expect(formatCm(50.8, "in")).toBe("20.0 in");
  });

  it("formats relative ages", () => {
    const now = new Date("2026-07-18T12:00:00Z");
    expect(formatAgo("2026-07-18T11:00:00Z", now)).toBe("1h");
    expect(formatAgo("2026-07-16T12:00:00Z", now)).toBe("2d");
    expect(formatAgo("2026-07-04T12:00:00Z", now)).toBe("2w");
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

  it("UTC-derived timestamp text is timezone-stable (review P2: no SSR/client drift)", () => {
    // 23:30Z sits on a different local calendar day in most timezones
    // (e.g. Lagos = +01:00 → May 23). The formatters must read the UTC
    // clock, so every host — server or browser — emits the same string.
    expect(formatTimeUtc("2026-07-14T13:58:00Z")).toBe("13:58");
    expect(formatTimeUtc("2026-05-22T23:30:00Z")).toBe("23:30");
    expect(formatDateUtc("2026-05-22T23:30:00Z")).toBe("22 May");
    expect(formatDateTimeUtc("2026-03-04T23:30:00Z")).toBe("Mar 4, 23:30");
    // Single-digit hour/minute pad ("09:05", not "9:5").
    expect(formatTimeUtc("2026-07-14T09:05:00Z")).toBe("09:05");
  });

  it("formatAgo's ≥30d fallback reads the UTC calendar day", () => {
    const now = new Date("2026-07-18T12:00:00Z");
    // Near-midnight instant: local rendering would flip this to "23 May"
    // on UTC+ hosts, splitting SSR (UTC) from the client.
    expect(formatAgo("2026-05-22T23:30:00Z", now)).toBe("22 May");
  });

  it("same-UTC-day check ignores the host timezone", () => {
    expect(isSameUtcDay("2026-05-22T23:30:00Z", "2026-05-22T00:10:00Z")).toBe(
      true,
    );
    expect(isSameUtcDay("2026-05-22T23:30:00Z", "2026-05-23T00:10:00Z")).toBe(
      false,
    );
  });
});
