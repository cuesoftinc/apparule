import { describe, expect, it } from "vitest";
import { act, fireEvent, render, screen, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MarketingNav } from "./MarketingNav";

describe("MarketingNav (§8.2b marketing)", () => {
  it("renders logo, canon links and the Sign in CTA", () => {
    render(<MarketingNav />);
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
    // canon revision: GitHub renders as the compact star badge
    const badge = screen.getByRole("link", {
      name: "Star cuesoftinc/apparule on GitHub",
    });
    expect(badge).toHaveAttribute(
      "href",
      "https://github.com/cuesoftinc/apparule",
    );
    expect(badge).toHaveTextContent("Star");
    expect(screen.getByRole("link", { name: "Sign in" })).toHaveAttribute(
      "href",
      "/signin",
    );
    expect(
      // two bar instances: desktop cluster + the <md bar CTA beside the
      // hamburger [Revised 2026-07-19 canon] — jsdom renders both.
      screen.getAllByRole("button", { name: "Try Cloud" })[0],
    ).toBeInTheDocument();
  });

  it("star badge is neutral until the live count arrives (never invented)", () => {
    const { rerender } = render(<MarketingNav starCount={null} />);
    expect(screen.getByTestId("star-badge")).toHaveTextContent("Star");
    rerender(<MarketingNav starCount={1234} />);
    expect(screen.getByTestId("star-badge")).toHaveTextContent("1,234");
  });

  it("the mobile panel's GitHub item mirrors the same live starCount (Codex P2)", async () => {
    const user = userEvent.setup();
    const { rerender } = render(<MarketingNav starCount={null} />);
    await user.click(screen.getByTestId("nav-menu-button"));
    const panel = screen.getByTestId("nav-menu-panel");
    const panelBadge = within(panel).getByRole("link", {
      name: "Star cuesoftinc/apparule on GitHub",
    });
    expect(panelBadge).toHaveTextContent("Star");

    rerender(<MarketingNav starCount={1234} />);
    expect(
      within(screen.getByTestId("nav-menu-panel")).getByRole("link", {
        name: "Star cuesoftinc/apparule on GitHub",
      }),
    ).toHaveTextContent("1,234");
  });

  it("badge aria-label is derived from a custom githubHref, not hardcoded (PR review fix)", async () => {
    const user = userEvent.setup();
    render(<MarketingNav githubHref="https://github.com/acme/widgets" />);
    // desktop badge
    expect(
      screen.getByRole("link", { name: "Star acme/widgets on GitHub" }),
    ).toHaveAttribute("href", "https://github.com/acme/widgets");
    // mobile panel badge mirrors the same derived label
    await user.click(screen.getByTestId("nav-menu-button"));
    const panel = screen.getByTestId("nav-menu-panel");
    expect(
      within(panel).getByRole("link", { name: "Star acme/widgets on GitHub" }),
    ).toHaveAttribute("href", "https://github.com/acme/widgets");
  });

  it("collapses the links into a hamburger disclosure below md", async () => {
    const user = userEvent.setup();
    render(
      <MarketingNav trailing={<button type="button">Toggle theme</button>} />,
    );
    const trigger = screen.getByTestId("nav-menu-button");
    expect(trigger).toHaveAttribute("aria-expanded", "false");
    expect(screen.queryByTestId("nav-menu-panel")).not.toBeInTheDocument();

    await user.click(trigger);
    expect(trigger).toHaveAttribute("aria-expanded", "true");
    const panel = screen.getByTestId("nav-menu-panel");
    // the same four canonical links + theme toggle + Sign in (canon ext.)
    expect(
      within(panel).getByRole("link", { name: "Features" }),
    ).toHaveAttribute("href", "#product");
    expect(
      within(panel).getByRole("link", { name: "For designers" }),
    ).toHaveAttribute("href", "#designers");
    expect(within(panel).getByRole("link", { name: "Docs" })).toHaveAttribute(
      "href",
      "https://cuesoft.gitbook.io/apparule",
    );
    // canon revision: the panel GitHub item is the same star badge as
    // desktop (aria-label + neutral "Star" label), not a plain text link.
    const panelBadge = within(panel).getByRole("link", {
      name: "Star cuesoftinc/apparule on GitHub",
    });
    expect(panelBadge).toHaveAttribute(
      "href",
      "https://github.com/cuesoftinc/apparule",
    );
    expect(panelBadge).toHaveTextContent("Star");
    expect(
      within(panel).getByRole("link", { name: "Sign in" }),
    ).toHaveAttribute("href", "/signin");
    // [Revised 2026-07-19 canon] the panel carries no duplicate Try Cloud —
    // the CTA stays on the bar beside the hamburger.
    expect(
      within(panel).queryByRole("button", { name: "Try Cloud" }),
    ).toBeNull();
    expect(
      within(panel).getByRole("button", { name: "Toggle theme" }),
    ).toBeInTheDocument();

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
    render(<MarketingNav />);
    const nav = screen.getByRole("navigation", { name: "Home" });
    expect(nav).toHaveAttribute("data-state", "top");
    act(() => {
      window.scrollY = 100;
      fireEvent.scroll(window);
    });
    expect(nav).toHaveAttribute("data-state", "stuck-blurred");
  });
});
