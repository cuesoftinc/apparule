import { describe, expect, it } from "vitest";
import { act, fireEvent, render, screen } from "@testing-library/react";
import { HomeNav } from "./HomeNav";

describe("HomeNav (§8.2b marketing)", () => {
  it("renders logo, canon links, star badge and the Sign in CTA", () => {
    render(<HomeNav />);
    expect(screen.getByText("Apparule")).toBeInTheDocument();
    // Parity canon (SKILL.md 2026-07-19): Features · For designers · Docs ·
    // GitHub (star badge) + the single Sign in CTA — no nav Try Cloud.
    expect(screen.getByRole("link", { name: "Features" })).toHaveAttribute(
      "href",
      "#product",
    );
    expect(screen.getByRole("link", { name: "For designers" })).toHaveAttribute(
      "href",
      "#designers",
    );
    expect(screen.getByRole("link", { name: "Docs" })).toHaveAttribute(
      "href",
      "https://cuesoft.gitbook.io/apparule",
    );
    expect(screen.getByTestId("star-badge")).toHaveAttribute(
      "href",
      "https://github.com/cuesoftinc/apparule",
    );
    expect(screen.getByRole("link", { name: "Sign in" })).toHaveAttribute(
      "href",
      "/signin",
    );
    expect(screen.queryByText("Try Cloud")).not.toBeInTheDocument();
  });

  it("star badge is neutral (no invented number) until the live count arrives", () => {
    const { rerender } = render(<HomeNav starCount={null} />);
    expect(screen.getByTestId("star-badge")).toHaveTextContent("Star");
    rerender(<HomeNav starCount={1234} />);
    expect(screen.getByTestId("star-badge")).toHaveTextContent("1,234");
  });

  it("blurs when stuck (scroll state)", () => {
    render(<HomeNav />);
    const nav = screen.getByRole("navigation", { name: "Home" });
    expect(nav).toHaveAttribute("data-state", "top");
    act(() => {
      window.scrollY = 100;
      fireEvent.scroll(window);
    });
    expect(nav).toHaveAttribute("data-state", "stuck-blurred");
  });
});
