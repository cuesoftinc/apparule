import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { PaymentBox, type PaymentBoxState } from "./PaymentBox";

const STATES: PaymentBoxState[] = [
  "quoted",
  "paying",
  "escrow-held",
  "released",
  "refunded",
  "dispute-frozen",
];

describe("PaymentBox (§8.2b, MI-15)", () => {
  it.each(STATES)("renders state=%s", (state) => {
    const { container } = render(
      <PaymentBox state={state} role="customer" quoteCents={4_500_000} />,
    );
    expect(container.querySelector(`[data-state="${state}"]`)).not.toBeNull();
  });

  it("customer quoted state shows the pay CTA with the amount", async () => {
    const onPay = vi.fn();
    render(
      <PaymentBox state="quoted" role="customer" quoteCents={4_500_000} onPay={onPay} />,
    );
    await userEvent.click(screen.getByRole("button", { name: "Pay ₦45,000" }));
    expect(onPay).toHaveBeenCalledOnce();
  });

  it("paying state spins and disables", () => {
    render(<PaymentBox state="paying" role="customer" quoteCents={4_500_000} />);
    expect(screen.getByRole("button", { name: /paying/i })).toBeDisabled();
  });

  it("escrow-held morphs to the shield-check (MI-15)", () => {
    render(<PaymentBox state="escrow-held" role="customer" quoteCents={4_500_000} />);
    expect(screen.getByTestId("shield-check")).toBeInTheDocument();
  });

  it("designer view itemizes the 10% fee line", () => {
    render(<PaymentBox state="released" role="designer" quoteCents={6_200_000} />);
    expect(screen.getByTestId("fee-line")).toHaveTextContent("−₦6,200");
    expect(screen.getByText("₦55,800")).toBeInTheDocument();
  });

  it("first-payment escrow explainer expands beneath (MI-15)", () => {
    render(
      <PaymentBox
        state="escrow-held"
        role="customer"
        quoteCents={4_500_000}
        showEscrowExplainer
      />,
    );
    expect(screen.getByTestId("escrow-explainer")).toHaveTextContent(/dispute/i);
  });

  it("dispute-frozen reads as an error state", () => {
    render(
      <PaymentBox state="dispute-frozen" role="designer" quoteCents={4_500_000} />,
    );
    expect(screen.getByText(/payout frozen/i)).toBeInTheDocument();
  });
});
