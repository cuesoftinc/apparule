import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import { ORDER_STATUSES } from "@/models";
import { StatusPill } from "./StatusPill";

describe("StatusPill (§8.2, MI-14)", () => {
  // Figma master (47:135): sentence-case labels ("In progress").
  const label = (status: string) => {
    const text = status.replace(/_/g, " ");
    return text.charAt(0).toUpperCase() + text.slice(1);
  };

  it("renders all 10 order states", () => {
    for (const status of ORDER_STATUSES) {
      const { unmount } = render(<StatusPill status={status} />);
      expect(screen.getByText(label(status))).toHaveAttribute(
        "data-status",
        status,
      );
      unmount();
    }
  });

  it.each(["fresh", "aging", "stale"] as const)(
    "renders freshness=%s",
    (freshness) => {
      const { container } = render(<StatusPill status={freshness} />);
      expect(screen.getByText(label(freshness))).toBeInTheDocument();
      expect(
        container.querySelector(`[data-status="${freshness}"]`),
      ).not.toBeNull();
    },
  );

  it("maps states to the decided tokens (spot checks)", () => {
    const { rerender } = render(<StatusPill status="quoted" />);
    expect(screen.getByText("Quoted").className).toContain("text-link");
    rerender(<StatusPill status="delivered" />);
    expect(screen.getByText("Delivered").className).toContain("text-success");
    rerender(<StatusPill status="in_progress" />);
    expect(screen.getByText("In progress").className).toContain("text-warn");
    rerender(<StatusPill status="disputed" />);
    expect(screen.getByText("Disputed").className).toContain("text-error");
    rerender(<StatusPill status="cancelled" />);
    expect(screen.getByText("Cancelled").className).toContain("text-text-2");
  });

  it("pulses once on status change (MI-14)", () => {
    const { rerender } = render(<StatusPill status="quoted" />);
    rerender(<StatusPill status="paid" />);
    expect(screen.getByText("Paid").className).toContain("status-pulse");
  });
});
