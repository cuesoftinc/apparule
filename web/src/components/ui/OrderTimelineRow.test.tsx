import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import { OrderTimelineRow } from "./OrderTimelineRow";

describe("OrderTimelineRow (§8.2b, MI-14)", () => {
  it.each(["done", "current", "pending", "terminal-error"] as const)(
    "renders dot=%s",
    (dot) => {
      const { container } = render(
        <OrderTimelineRow dot={dot} label="Quoted" />,
      );
      expect(container.querySelector(`[data-dot="${dot}"]`)).not.toBeNull();
    },
  );

  it("connector drawn/undrawn/none", () => {
    const { container, rerender } = render(
      <OrderTimelineRow dot="done" connector="drawn" label="Paid" />,
    );
    expect(screen.getByTestId("connector")).toBeInTheDocument();
    rerender(<OrderTimelineRow dot="done" connector="undrawn" label="Paid" />);
    expect(screen.getByTestId("connector")).toBeInTheDocument();
    rerender(<OrderTimelineRow dot="done" connector="none" label="Paid" />);
    expect(container.querySelector('[data-testid="connector"]')).toBeNull();
  });

  it("renders label + timestamp", () => {
    // Figma master (89:1075): absolute "Jul 12, 14:02"-style stamp under
    // the label.
    render(
      <OrderTimelineRow
        dot="done"
        label="Requested"
        timestamp="2026-07-12T14:02:00"
      />,
    );
    expect(screen.getByText("Requested")).toBeInTheDocument();
    expect(screen.getByText("Jul 12, 14:02")).toBeInTheDocument();
  });
});
