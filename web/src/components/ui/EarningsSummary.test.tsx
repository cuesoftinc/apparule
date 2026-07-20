import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import { EarningsSummary, TransactionRow } from "./EarningsSummary";
import { fixtureEarnings } from "./fixtures";

describe("EarningsSummary + TransactionRow (§8.2b)", () => {
  it("renders balance (released) and pending (escrow) cards", () => {
    render(<EarningsSummary earnings={fixtureEarnings} />);
    expect(screen.getByTestId("balance-card")).toHaveTextContent("₦55,800");
    expect(screen.getByTestId("pending-card")).toHaveTextContent("₦40,500");
  });

  it.each(["payout", "escrow_held", "fee_line"] as const)(
    "TransactionRow renders kind=%s",
    (kind) => {
      const entry = fixtureEarnings.transactions.find((t) => t.kind === kind)!;
      const { container } = render(<TransactionRow entry={entry} />);
      expect(container.querySelector(`[data-kind="${kind}"]`)).not.toBeNull();
    },
  );

  it("payout rows carry the provider ref; fee lines render negative", () => {
    const payout = fixtureEarnings.transactions[0];
    render(<TransactionRow entry={payout} />);
    expect(screen.getByText(/PSTK-TRF-1058/)).toBeInTheDocument();
    const fee = fixtureEarnings.transactions[1];
    render(<TransactionRow entry={fee} />);
    expect(screen.getByText("−₦6,200")).toBeInTheDocument();
  });

  it("old payout dates read the UTC calendar day — SSR/client-stable (review P2)", () => {
    // 23:30Z on Jan 15: a host in Lagos (+01:00) would locally render
    // "16 Jan" while a UTC server said "15 Jan" — a hydration mismatch
    // and visible date flip. The ≥30d fallback derives from UTC.
    const entry = {
      ...fixtureEarnings.transactions[0],
      created_at: "2026-01-15T23:30:00Z",
    };
    render(<TransactionRow entry={entry} />);
    const time = screen.getByText("15 Jan");
    expect(time.tagName).toBe("TIME");
    expect(time).toHaveAttribute("dateTime", "2026-01-15T23:30:00Z");
  });
});
