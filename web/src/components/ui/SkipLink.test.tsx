import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import SkipLink from "./SkipLink";

describe("SkipLink (fleet a11y canon)", () => {
  it("is a link to #main, visually hidden until focused", () => {
    render(<SkipLink />);
    const link = screen.getByRole("link", { name: "Skip to content" });
    expect(link).toHaveAttribute("href", "#main");
    // Visually hidden via sr-only until :focus reveals the pill — it must
    // stay in the tab order (never display:none / visibility:hidden).
    expect(link.className).toContain("sr-only");
    expect(link.className).toContain("focus:not-sr-only");
  });
});
