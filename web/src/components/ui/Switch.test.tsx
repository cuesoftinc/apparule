import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { Switch } from "./Switch";

describe("Switch (§8.2b)", () => {
  it("renders on/off states", () => {
    const { rerender } = render(
      <Switch checked onCheckedChange={() => {}} aria-label="Quotes" />,
    );
    expect(screen.getByRole("switch")).toHaveAttribute("data-state", "checked");
    rerender(
      <Switch checked={false} onCheckedChange={() => {}} aria-label="Quotes" />,
    );
    expect(screen.getByRole("switch")).toHaveAttribute(
      "data-state",
      "unchecked",
    );
  });

  it("toggles via click", async () => {
    const onChange = vi.fn();
    render(
      <Switch checked={false} onCheckedChange={onChange} aria-label="Quotes" />,
    );
    await userEvent.click(screen.getByRole("switch"));
    expect(onChange).toHaveBeenCalledWith(true);
  });

  it("disabled blocks toggling", async () => {
    const onChange = vi.fn();
    render(
      <Switch
        checked={false}
        disabled
        onCheckedChange={onChange}
        aria-label="Quotes"
      />,
    );
    await userEvent.click(screen.getByRole("switch"));
    expect(onChange).not.toHaveBeenCalled();
    expect(screen.getByRole("switch")).toBeDisabled();
  });
});
