import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import { TabBar, DEFAULT_TAB_ITEMS } from "./TabBar";

describe("TabBar (§8.2)", () => {
  it("renders the five tabs — Home · Explore · Create · Orders · Profile", () => {
    render(<TabBar activeKey="home" />);
    const links = screen.getAllByRole("link");
    expect(links).toHaveLength(5);
    expect(DEFAULT_TAB_ITEMS.map((i) => i.label)).toEqual([
      "Home",
      "Explore",
      "Create",
      "Orders",
      "Profile",
    ]);
  });

  it.each(DEFAULT_TAB_ITEMS.map((i) => i.key))(
    "marks active tab ×5 — %s",
    (key) => {
      render(<TabBar activeKey={key} />);
      const active = screen
        .getAllByRole("link")
        .filter((l) => l.getAttribute("aria-current") === "page");
      expect(active).toHaveLength(1);
      expect(active[0]).toHaveAttribute("data-state", "active");
    },
  );

  it("landmark label defaults to Tabs and is overridable (landmark rules)", () => {
    const { rerender } = render(<TabBar activeKey="home" />);
    expect(screen.getByRole("navigation", { name: "Tabs" })).toBeVisible();
    rerender(<TabBar activeKey="home" ariaLabel="Tabs (explore thumb)" />);
    expect(
      screen.getByRole("navigation", { name: "Tabs (explore thumb)" }),
    ).toBeVisible();
  });

  it("Orders badge: none by default", () => {
    render(<TabBar activeKey="home" />);
    expect(screen.queryByTestId("tab-badge")).not.toBeInTheDocument();
  });

  it("Orders badge: count renders on the Orders tab (MI-16)", () => {
    render(<TabBar activeKey="home" ordersBadge={3} />);
    const badge = screen.getByTestId("tab-badge");
    expect(badge).toHaveTextContent("3");
    expect(screen.getByLabelText("Orders")).toContainElement(badge);
  });
});
