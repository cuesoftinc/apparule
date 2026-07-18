import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { addDays, startOfDay } from "date-fns";
import { DateInput, DatePickerPopover, minDueDate } from "./DateInput";

describe("DateInput (§8.2b)", () => {
  it("renders placeholder then the picked date", () => {
    const { rerender } = render(
      <DateInput aria-label="Due date" value={null} onChange={() => {}} />,
    );
    expect(screen.getByText("Pick a date")).toBeInTheDocument();
    rerender(
      <DateInput
        aria-label="Due date"
        value={new Date("2026-08-10T00:00:00")}
        onChange={() => {}}
      />,
    );
    expect(screen.getByText("10 Aug 2026")).toBeInTheDocument();
  });

  it("soft-warns when the value is before softMinDate (turnaround rule)", () => {
    render(
      <DateInput
        aria-label="Target date"
        value={new Date()}
        onChange={() => {}}
        softMinDate={addDays(new Date(), 14)}
      />,
    );
    expect(
      screen.getByText(/earlier than the designer's stated turnaround/i),
    ).toBeInTheDocument();
  });

  it("error state renders the message", () => {
    render(
      <DateInput
        aria-label="Due date"
        value={null}
        onChange={() => {}}
        error="Required"
      />,
    );
    expect(screen.getByText("Required")).toBeInTheDocument();
  });

  it("minDueDate is tomorrow (due_at ≥ today+1)", () => {
    const min = minDueDate(new Date("2026-07-18T15:00:00"));
    expect(min.getTime()).toBe(startOfDay(new Date("2026-07-19T00:00:00")).getTime());
  });

  it("DatePickerPopover disables days before minDate", async () => {
    const onSelect = vi.fn();
    const base = new Date("2026-07-15T00:00:00");
    render(
      <DatePickerPopover value={base} minDate={base} onSelect={onSelect} />,
    );
    const day14 = screen.getByRole("button", { name: "14" });
    expect(day14).toBeDisabled();
    await userEvent.click(screen.getByRole("button", { name: "20" }));
    expect(onSelect).toHaveBeenCalled();
  });
});
