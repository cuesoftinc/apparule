import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { Chip } from "./Chip";

describe("Chip (§8.2)", () => {
  it.each(["default", "selected", "removable"] as const)(
    "renders kind=%s",
    (kind) => {
      render(<Chip kind={kind} label="ankara" />);
      // exact match — removable chips nest a "Remove ankara" affordance
      expect(screen.getByRole("button", { name: "ankara" })).toHaveAttribute(
        "data-kind",
        kind,
      );
    },
  );

  it("never wraps its label (pill contract, system QA)", () => {
    render(<Chip label="2-week turnaround" />);
    expect(
      screen.getByRole("button", { name: "2-week turnaround" }),
    ).toHaveClass("whitespace-nowrap");
  });

  it("selected chip exposes aria-pressed", () => {
    render(<Chip kind="selected" label="aso-oke" />);
    expect(screen.getByRole("button", { name: "aso-oke" })).toHaveAttribute(
      "aria-pressed",
      "true",
    );
  });

  it("the ✕ affordance is a real, keyboard-reachable button (semantic canon)", () => {
    render(<Chip kind="removable" label="near me" onRemove={() => {}} />);
    const remove = screen.getByRole("button", { name: "Remove near me" });
    expect(remove.tagName).toBe("BUTTON");
    expect(remove).not.toHaveAttribute("tabindex", "-1");
  });

  it("removable chip fires onRemove from the ✕ affordance only", async () => {
    const onRemove = vi.fn();
    const onClick = vi.fn();
    render(
      <Chip
        kind="removable"
        label="near me"
        onRemove={onRemove}
        onClick={onClick}
      />,
    );
    await userEvent.click(
      screen.getByRole("button", { name: "Remove near me" }),
    );
    expect(onRemove).toHaveBeenCalledOnce();
    expect(onClick).not.toHaveBeenCalled();
  });

  it("disabled removable chip also disables the ✕ — no onRemove from a mouse click", async () => {
    const onRemove = vi.fn();
    render(
      <Chip kind="removable" label="near me" onRemove={onRemove} disabled />,
    );
    const remove = screen.getByRole("button", { name: "Remove near me" });
    expect(remove).toBeDisabled();
    await userEvent.click(remove);
    expect(onRemove).not.toHaveBeenCalled();
  });

  it("disabled removable chip's ✕ ignores keyboard activation too", async () => {
    const onRemove = vi.fn();
    render(
      <Chip kind="removable" label="near me" onRemove={onRemove} disabled />,
    );
    const remove = screen.getByRole("button", { name: "Remove near me" });
    remove.focus();
    await userEvent.keyboard("{Enter}");
    await userEvent.keyboard(" ");
    expect(onRemove).not.toHaveBeenCalled();
  });

  it("disabled removable chip disables the label button too", () => {
    render(
      <Chip kind="removable" label="near me" onRemove={() => {}} disabled />,
    );
    expect(screen.getByRole("button", { name: "near me" })).toBeDisabled();
  });
});
