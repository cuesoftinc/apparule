import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { AppBar } from "./AppBar";

describe("AppBar (§8.2b)", () => {
  it.each(["root", "sub", "over-media"] as const)("renders kind=%s", (kind) => {
    render(<AppBar kind={kind} title="Orders" onBack={() => {}} />);
    expect(screen.getByRole("banner")).toHaveAttribute("data-kind", kind);
  });

  it("root: title + trailing action slot, no back chevron", () => {
    render(
      <AppBar
        title="Apparule"
        trailing={<button type="button">Bell</button>}
      />,
    );
    expect(screen.getByText("Apparule")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Bell" })).toBeInTheDocument();
    expect(
      screen.queryByRole("button", { name: "Back" }),
    ).not.toBeInTheDocument();
  });

  it("sub: chevron-left fires onBack", async () => {
    const onBack = vi.fn();
    render(<AppBar kind="sub" title="Order #APR-1042" onBack={onBack} />);
    await userEvent.click(screen.getByRole("button", { name: "Back" }));
    expect(onBack).toHaveBeenCalledOnce();
  });

  it("over-media: transparent chrome (no border/bg surface)", () => {
    render(<AppBar kind="over-media" onBack={() => {}} />);
    const bar = screen.getByRole("banner");
    expect(bar.className).not.toContain("border-b");
    expect(bar.className).toContain("to-transparent");
  });
});
