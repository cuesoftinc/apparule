import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import { ThemeProvider } from "@/design/ThemeProvider";
import { DEFAULT_NAV_ITEMS, NavRail } from "./NavRail";

function renderRail(props: Partial<Parameters<typeof NavRail>[0]> = {}) {
  return render(
    <ThemeProvider>
      <NavRail activeKey="home" {...props} />
    </ThemeProvider>,
  );
}

describe("NavRail (§8.2b)", () => {
  it("renders the seven items", () => {
    renderRail({ expanded: true });
    expect(DEFAULT_NAV_ITEMS).toHaveLength(7);
    for (const item of DEFAULT_NAV_ITEMS) {
      expect(
        screen.getByRole("link", { name: item.label }),
      ).toBeInTheDocument();
    }
  });

  it("marks the active item with aria-current", () => {
    renderRail({ expanded: true, activeKey: "orders" });
    expect(screen.getByRole("link", { name: "Orders" })).toHaveAttribute(
      "aria-current",
      "page",
    );
  });

  it("collapsed 72 / expanded 244 widths", () => {
    const { rerender } = renderRail();
    expect(screen.getByRole("navigation")).toHaveAttribute(
      "data-expanded",
      "false",
    );
    rerender(
      <ThemeProvider>
        <NavRail activeKey="home" expanded />
      </ThemeProvider>,
    );
    expect(screen.getByRole("navigation")).toHaveAttribute(
      "data-expanded",
      "true",
    );
  });

  it("footer slot carries theme toggle + support link", () => {
    renderRail({ expanded: true });
    // Tri-state cycle (theme contract 2026-07-20): the label announces
    // the active mode and the next one.
    expect(
      screen.getByRole("button", { name: /^Theme: .* — switch to .*/ }),
    ).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /support/i })).toHaveAttribute(
      "href",
      "https://clients.cuesoft.io",
    );
  });

  it("renders the Orders badge (MI-16)", () => {
    renderRail({
      items: DEFAULT_NAV_ITEMS.map((i) =>
        i.key === "orders" ? { ...i, badge: 3 } : i,
      ),
    });
    expect(screen.getByTestId("nav-badge")).toHaveTextContent("3");
  });
});
