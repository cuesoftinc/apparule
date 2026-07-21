import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { SkipLink } from "./SkipLink";

describe("SkipLink (P15 fleet a11y canon)", () => {
  it("is a link to #main, hidden off-viewport until focused", () => {
    render(<SkipLink />);
    const link = screen.getByRole("link", { name: "Skip to content" });
    expect(link).toHaveAttribute("href", "#main");
    // Off-viewport via transform until :focus pulls it back in — it must
    // stay in the tab order (never display:none / visibility:hidden).
    expect(link.className).toContain("-translate-y-[150%]");
    expect(link.className).toContain("focus:translate-y-0");
  });
});
