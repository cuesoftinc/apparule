"use client";

// PaymentBox — design.md §8.2b (MI-15): state quoted (pay CTA) / paying
// (spinner) / escrow-held (shield-check + first-payment explainer expand) /
// released / refunded / dispute-frozen · role customer / designer ·
// itemized 10% fee line (A-1).
import clsx from "clsx";
import { Info, ShieldCheck } from "lucide-react";
import { formatNaira } from "@/lib/format";
import { Button } from "./Button";

export type PaymentBoxState =
  | "quoted"
  | "paying"
  | "escrow-held"
  | "released"
  | "refunded"
  | "dispute-frozen";

export interface PaymentBoxProps {
  state: PaymentBoxState;
  role: "customer" | "designer";
  quoteCents: number;
  currency?: string;
  /** MI-15: escrow explainer expands beneath on first payment. */
  showEscrowExplainer?: boolean;
  onPay?: () => void;
  className?: string;
}

const FEE_RATE = 0.1; // 10% platform fee (A-1, ratified)

const STATE_LINE: Record<PaymentBoxState, string> = {
  quoted: "Quote ready — payment is held in escrow until you confirm delivery",
  paying: "Processing payment…",
  "escrow-held": "Payment held in escrow",
  released: "Payout released",
  refunded: "Payment refunded",
  "dispute-frozen": "Payout frozen while the dispute is resolved",
};

export function PaymentBox({
  state,
  role,
  quoteCents,
  currency = "NGN",
  showEscrowExplainer = false,
  onPay,
  className,
}: PaymentBoxProps) {
  const fee = Math.round(quoteCents * FEE_RATE);
  const net = quoteCents - fee;

  return (
    <section
      data-state={state}
      data-role={role}
      aria-label="Payment"
      className={clsx(
        "flex flex-col gap-3 rounded-card border border-border bg-bg-elev p-4",
        className,
      )}
    >
      <div className="flex items-center justify-between">
        <span className="text-body font-semibold text-text">Payment</span>
        {(state === "escrow-held" || state === "released") && (
          <ShieldCheck
            data-testid="shield-check"
            size={20}
            className="text-success"
          />
        )}
      </div>

      <dl className="flex flex-col gap-1.5 text-body">
        <div className="flex justify-between">
          <dt className="text-text-2">Quote</dt>
          <dd className="tnum font-semibold text-text">
            {formatNaira(quoteCents, currency)}
          </dd>
        </div>
        {role === "designer" ? (
          <>
            <div className="flex justify-between" data-testid="fee-line">
              <dt className="text-text-2">Platform fee (10%)</dt>
              <dd className="tnum text-text-2">−{formatNaira(fee, currency)}</dd>
            </div>
            <div className="flex justify-between border-t border-border pt-1.5">
              <dt className="font-semibold text-text">Your payout</dt>
              <dd className="tnum font-semibold text-text">
                {formatNaira(net, currency)}
              </dd>
            </div>
          </>
        ) : null}
      </dl>

      <p
        className={clsx(
          "text-caption",
          state === "dispute-frozen"
            ? "text-error"
            : state === "refunded"
              ? "text-warn"
              : "text-text-2",
        )}
      >
        {STATE_LINE[state]}
      </p>

      {role === "customer" && (state === "quoted" || state === "paying") ? (
        <Button
          kind="gradient-primary"
          loading={state === "paying"}
          onClick={onPay}
          className="w-full"
        >
          {state === "paying" ? "Paying…" : `Pay ${formatNaira(quoteCents, currency)}`}
        </Button>
      ) : null}

      {showEscrowExplainer ? (
        <div
          data-testid="escrow-explainer"
          className="flex items-start gap-2 rounded-card bg-border/20 p-3 text-caption text-text-2"
        >
          <Info size={16} className="mt-0.5 shrink-0" />
          <span>
            Your money stays with Apparule — not the designer — until you
            confirm delivery. If anything goes wrong, you can open a dispute
            and get refunded.
          </span>
        </div>
      ) : null}
    </section>
  );
}
