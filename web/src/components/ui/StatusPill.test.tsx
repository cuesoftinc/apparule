import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import { ORDER_STATUSES } from "@/models";
import { StatusPill } from "./StatusPill";

describe("StatusPill (§8.2, MI-14)", () => {
  it("renders all 10 order states", () => {
    for (const status of ORDER_STATUSES) {
      const { unmount } = render(<StatusPill status={status} />);
      expect(
        screen.getByText(status.replace(/_/g, " ")),
      ).toHaveAttribute("data-status", status);
      unmount();
    }
  });

  it.each(["fresh", "aging", "stale"] as const)(
    "renders freshness=%s",
    (freshness) => {
      render(<StatusPill status={freshness} />);
      expect(screen.getByText(freshness)).toHaveAttribute("data-status", freshness);
    },
  );

  it("maps states to the decided tokens (spot checks)", () => {
    const { rerender } = render(<StatusPill status="quoted" />);
    expect(screen.getByText("quoted").className).toContain("text-link");
    rerender(<StatusPill status="delivered" />);
    expect(screen.getByText("delivered").className).toContain("text-success");
    rerender(<StatusPill status="in_progress" />);
    expect(screen.getByText("in progress").className).toContain("text-warn");
    rerender(<StatusPill status="disputed" />);
    expect(screen.getByText("disputed").className).toContain("text-error");
    rerender(<StatusPill status="cancelled" />);
    expect(screen.getByText("cancelled").className).toContain("text-text-2");
  });

  it("pulses once on status change (MI-14)", () => {
    const { rerender } = render(<StatusPill status="quoted" />);
    rerender(<StatusPill status="paid" />);
    expect(screen.getByText("paid").className).toContain("status-pulse");
  });
});
