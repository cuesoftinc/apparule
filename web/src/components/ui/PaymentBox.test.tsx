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
    const { container } = render(
      <PaymentBox state="paying" role="customer" quoteCents={4_500_000} />,
    );
    // Figma Button master: loading swaps the label for a spinner
    const paying = container.querySelector('button[aria-busy="true"]');
    expect(paying).not.toBeNull();
    expect(paying).toBeDisabled();
  });

  it("escrow-held morphs to the shield-check (MI-15)", () => {
    render(<PaymentBox state="escrow-held" role="customer" quoteCents={4_500_000} />);
    expect(screen.getByTestId("shield-check")).toBeInTheDocument();
  });

  it("designer view itemizes the 10% fee line", () => {
    // Figma master (90:1025): the fee is itemized in the quoted body copy
    render(<PaymentBox state="quoted" role="designer" quoteCents={6_200_000} />);
    expect(screen.getByTestId("fee-line")).toHaveTextContent(
      "You receive ₦55,800 after the 10% platform fee",
    );
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
    // Figma master (90:1093) copy + designer action
    expect(screen.getByText(/funds frozen/i)).toBeInTheDocument();
    expect(
      screen.getByRole("button", { name: "Respond to dispute" }),
    ).toBeInTheDocument();
  });
});
