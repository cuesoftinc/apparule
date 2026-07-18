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
});
