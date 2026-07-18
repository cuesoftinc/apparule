import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { Input } from "./Input";

describe("Input (§8.2 + §8.2b kinds)", () => {
  it.each(["text", "numeric", "search", "currency"] as const)(
    "renders kind=%s",
    (kind) => {
      const { container } = render(<Input kind={kind} aria-label="field" />);
      expect(container.querySelector(`[data-kind="${kind}"]`)).not.toBeNull();
    },
  );

  it("error state exposes aria-invalid + message", () => {
    render(<Input aria-label="username" error="That username is taken" />);
    expect(screen.getByLabelText("username")).toHaveAttribute("aria-invalid", "true");
    expect(screen.getByText("That username is taken")).toBeInTheDocument();
  });

  it("disabled state disables the control", () => {
    render(<Input aria-label="field" disabled />);
    expect(screen.getByLabelText("field")).toBeDisabled();
  });

  it("numeric kind flips cm/in via the unit toggle (MI-13)", async () => {
    const onUnitChange = vi.fn();
    render(
      <Input
        kind="numeric"
        aria-label="shoulder"
        unit="cm"
        onUnitChange={onUnitChange}
      />,
    );
    await userEvent.click(
      screen.getByRole("button", { name: /switch units/i }),
    );
    expect(onUnitChange).toHaveBeenCalledWith("in");
  });

  it("currency kind shows the ₦ prefix", () => {
    render(<Input kind="currency" aria-label="budget" />);
    expect(screen.getByText("₦")).toBeInTheDocument();
  });

  it("textarea kind counts down from 500 (0–500 counter)", async () => {
    function Wrapper() {
      return <Input kind="textarea" aria-label="notes" value="hello" onChange={() => {}} />;
    }
    render(<Wrapper />);
    expect(screen.getByText("5/500")).toBeInTheDocument();
  });
});
