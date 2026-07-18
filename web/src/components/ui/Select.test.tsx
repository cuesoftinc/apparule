import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { Select } from "./Select";

const options = [
  { value: "workload", label: "Fully booked right now" },
  { value: "budget_too_low", label: "Budget too low" },
];

describe("Select / OptionRow (§8.2b)", () => {
  it("renders the trigger with placeholder", () => {
    render(
      <Select
        aria-label="Decline reason"
        options={options}
        value={undefined}
        onValueChange={() => {}}
        placeholder="Why are you declining?"
      />,
    );
    expect(screen.getByText("Why are you declining?")).toBeInTheDocument();
  });

  it("error state renders the message + aria-invalid", () => {
    render(
      <Select
        aria-label="State"
        options={options}
        value={undefined}
        onValueChange={() => {}}
        error="Pick a state"
      />,
    );
    expect(screen.getByText("Pick a state")).toBeInTheDocument();
    expect(screen.getByRole("combobox")).toHaveAttribute("aria-invalid", "true");
  });

  it("disabled state blocks opening", () => {
    render(
      <Select
        aria-label="Bank"
        options={options}
        value={undefined}
        onValueChange={() => {}}
        disabled
      />,
    );
    expect(screen.getByRole("combobox")).toBeDisabled();
  });

  it("opens and selects an option (OptionRow)", async () => {
    const onValueChange = vi.fn();
    render(
      <Select
        aria-label="Decline reason"
        options={options}
        value={undefined}
        onValueChange={onValueChange}
      />,
    );
    await userEvent.click(screen.getByRole("combobox"));
    await userEvent.click(
      await screen.findByRole("option", { name: "Budget too low" }),
    );
    expect(onValueChange).toHaveBeenCalledWith("budget_too_low");
  });
});
