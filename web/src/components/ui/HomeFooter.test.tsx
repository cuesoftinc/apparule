import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import { HomeFooter } from "./HomeFooter";

describe("HomeFooter (§8.2b marketing, pages.md A10)", () => {
  it("renders the three link columns", () => {
    render(<HomeFooter />);
    for (const heading of ["Product", "Docs", "Community"]) {
      expect(screen.getByRole("heading", { name: heading })).toBeInTheDocument();
    }
  });

  it("renders legal links incl. the privacy.cuesoft.io clause link", () => {
    render(<HomeFooter />);
    expect(screen.getByRole("link", { name: "Privacy" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Terms" })).toBeInTheDocument();
    expect(
      screen.getByRole("link", { name: "privacy.cuesoft.io" }),
    ).toHaveAttribute("href", "https://privacy.cuesoft.io");
  });

  it("renders the language selector", () => {
    render(<HomeFooter />);
    expect(screen.getByLabelText("Language")).toBeInTheDocument();
  });
});
