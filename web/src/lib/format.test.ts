import { describe, expect, it } from "vitest";
import { formatAgo, formatCm, formatNaira } from "./format";

describe("format utilities", () => {
  it("formats kobo to naira", () => {
    expect(formatNaira(4_500_000)).toBe("₦45,000");
    expect(formatNaira(6_200_000)).toBe("₦62,000");
    expect(formatNaira(-620_000)).toBe("−₦6,200");
  });

  it("formats centimetres and inches", () => {
    expect(formatCm(42.5)).toBe("42.5 cm");
    expect(formatCm(42)).toBe("42 cm");
    expect(formatCm(50.8, "in")).toBe("20.0 in");
  });

  it("formats relative ages", () => {
    const now = new Date("2026-07-18T12:00:00Z");
    expect(formatAgo("2026-07-18T11:00:00Z", now)).toBe("1h");
    expect(formatAgo("2026-07-16T12:00:00Z", now)).toBe("2d");
    expect(formatAgo("2026-07-04T12:00:00Z", now)).toBe("2w");
  });
});
