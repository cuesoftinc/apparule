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
    render(
      <OrderTimelineRow
        dot="done"
        label="Requested"
        timestamp={new Date(Date.now() - 2 * 86_400_000).toISOString()}
      />,
    );
    expect(screen.getByText("Requested")).toBeInTheDocument();
    expect(screen.getByText("2d")).toBeInTheDocument();
  });
});
