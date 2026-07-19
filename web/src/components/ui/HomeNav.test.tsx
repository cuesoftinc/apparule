import { describe, expect, it } from "vitest";
import { act, fireEvent, render, screen, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { HomeNav } from "./HomeNav";

describe("HomeNav (§8.2b marketing)", () => {
  it("renders logo, canon links and the Sign in CTA", () => {
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
    expect(screen.getByRole("link", { name: "GitHub" })).toHaveAttribute(
      "href",
      "https://github.com/cuesoftinc/apparule",
    );
    // adjudicated: plain text link — no star badge in the nav
    expect(screen.queryByTestId("star-badge")).not.toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Sign in" })).toHaveAttribute(
      "href",
      "/signin",
    );
    expect(screen.queryByText("Try Cloud")).not.toBeInTheDocument();
  });

  it("collapses the links into a hamburger disclosure below md", async () => {
    const user = userEvent.setup();
    render(<HomeNav trailing={<button type="button">Toggle theme</button>} />);
    const trigger = screen.getByTestId("nav-menu-button");
    expect(trigger).toHaveAttribute("aria-expanded", "false");
    expect(screen.queryByTestId("nav-menu-panel")).not.toBeInTheDocument();

    await user.click(trigger);
    expect(trigger).toHaveAttribute("aria-expanded", "true");
    const panel = screen.getByTestId("nav-menu-panel");
    // the same four canonical links + theme toggle + Sign in (canon ext.)
    expect(within(panel).getByRole("link", { name: "Features" })).toHaveAttribute("href", "#product");
    expect(within(panel).getByRole("link", { name: "For designers" })).toHaveAttribute("href", "#designers");
    expect(within(panel).getByRole("link", { name: "Docs" })).toHaveAttribute(
      "href",
      "https://cuesoft.gitbook.io/apparule",
    );
    expect(within(panel).getByRole("link", { name: "GitHub" })).toHaveAttribute(
      "href",
      "https://github.com/cuesoftinc/apparule",
    );
    expect(within(panel).getByRole("link", { name: "Sign in" })).toHaveAttribute("href", "/signin");
    expect(within(panel).getByRole("button", { name: "Toggle theme" })).toBeInTheDocument();

    // link click closes the disclosure
    await user.click(within(panel).getByRole("link", { name: "Features" }));
    expect(screen.queryByTestId("nav-menu-panel")).not.toBeInTheDocument();
    expect(trigger).toHaveAttribute("aria-expanded", "false");

    // Escape closes too
    await user.click(trigger);
    expect(screen.getByTestId("nav-menu-panel")).toBeInTheDocument();
    await user.keyboard("{Escape}");
    expect(screen.queryByTestId("nav-menu-panel")).not.toBeInTheDocument();
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
