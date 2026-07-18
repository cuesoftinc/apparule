import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { Tabs } from "./Tabs";

describe("Tabs (§8.2b as built)", () => {
  it("text kind renders the two role labels", () => {
    render(<Tabs active="first" onChange={() => {}} />);
    expect(screen.getByRole("tab", { name: "As customer" })).toBeInTheDocument();
    expect(screen.getByRole("tab", { name: "As designer" })).toBeInTheDocument();
  });

  it("icon kind renders grid + saved tabs", () => {
    render(<Tabs kind="icon" active="first" onChange={() => {}} />);
    expect(screen.getByRole("tab", { name: "Grid" })).toBeInTheDocument();
    expect(screen.getByRole("tab", { name: "Saved" })).toBeInTheDocument();
  });

  it("active axis first/second drives selection + underline", () => {
    const { rerender } = render(<Tabs active="first" onChange={() => {}} />);
    expect(screen.getByRole("tab", { name: "As customer" })).toHaveAttribute(
      "aria-selected",
      "true",
    );
    rerender(<Tabs active="second" onChange={() => {}} />);
    expect(screen.getByRole("tab", { name: "As designer" })).toHaveAttribute(
      "aria-selected",
      "true",
    );
    expect(screen.getByTestId("tab-indicator")).toBeInTheDocument();
  });

  it("clicking fires onChange", async () => {
    const onChange = vi.fn();
    render(<Tabs active="first" onChange={onChange} />);
    await userEvent.click(screen.getByRole("tab", { name: "As designer" }));
    expect(onChange).toHaveBeenCalledWith("second");
  });
});
