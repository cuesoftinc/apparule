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

  it("selected chip exposes aria-pressed", () => {
    render(<Chip kind="selected" label="aso-oke" />);
    expect(screen.getByRole("button", { name: "aso-oke" })).toHaveAttribute(
      "aria-pressed",
      "true",
    );
  });

  it("removable chip fires onRemove from the ✕ affordance only", async () => {
    const onRemove = vi.fn();
    const onClick = vi.fn();
    render(
      <Chip kind="removable" label="near me" onRemove={onRemove} onClick={onClick} />,
    );
    await userEvent.click(screen.getByRole("button", { name: "Remove near me" }));
    expect(onRemove).toHaveBeenCalledOnce();
    expect(onClick).not.toHaveBeenCalled();
  });
});
