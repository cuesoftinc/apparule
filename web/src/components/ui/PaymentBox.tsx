"use client";

// PaymentBox — design.md §8.2b (MI-15): state quoted (pay CTA) / paying
// (spinner) / escrow-held (shield-check + first-payment explainer expand) /
// released / refunded / dispute-frozen · role customer / designer ·
// itemized 10% fee line (A-1).
import clsx from "clsx";
import {
  AlertTriangle,
  Check,
  Clock,
  Info,
  ShieldCheck,
  type LucideIcon,
} from "lucide-react";
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
  /** Secondary CTAs (Edit quote / View payout / dispute actions). */
  onAction?: (label: string) => void;
  className?: string;
}

const FEE_RATE = 0.1; // 10% platform fee (A-1, ratified)

interface PaymentShape {
  icon?: LucideIcon;
  iconClass?: string;
  headline: string;
  body: string;
  /** body carries the itemized fee copy (design.md §8.2b fee line). */
  bodyIsFeeLine?: boolean;
  cta?: {
    label: string;
    kind: "gradient-primary" | "quiet";
    loading?: boolean;
  };
}

// Figma masters (90:1103) — copy and anatomy per state × role.
function shapeFor(
  state: PaymentBoxState,
  role: "customer" | "designer",
  price: string,
  fee: string,
  net: string,
): PaymentShape {
  switch (state) {
    case "quoted":
      return role === "customer"
        ? {
            headline: `Quote · ${price}`,
            body: `Includes 10% platform fee · ${fee}`,
            bodyIsFeeLine: true,
            cta: { label: `Pay ${price}`, kind: "gradient-primary" },
          }
        : {
            headline: `Quote sent · ${price}`,
            body: `You receive ${net} after the 10% platform fee`,
            bodyIsFeeLine: true,
            cta: { label: "Edit quote", kind: "quiet" },
          };
    case "paying":
      return role === "customer"
        ? {
            headline: `Quote · ${price}`,
            body: "Confirming payment with your bank…",
            cta: { label: "Paying", kind: "gradient-primary", loading: true },
          }
        : {
            headline: "Payment in progress",
            body: "The customer is completing payment",
          };
    case "escrow-held":
      return {
        icon: ShieldCheck,
        iconClass: "text-success",
        headline: `${price} held in escrow`,
        body:
          role === "customer"
            ? "Funds release to the designer when you confirm delivery"
            : `${net} releases to you on delivery confirmation`,
      };
    case "released":
      return role === "customer"
        ? {
            icon: Check,
            iconClass: "text-success",
            headline: "Payment released",
            body: "You confirmed delivery — order complete",
          }
        : {
            icon: Check,
            iconClass: "text-success",
            headline: `${net} released to you`,
            body: "Payout arrives within 2 business days",
            cta: { label: "View payout", kind: "quiet" },
          };
    case "refunded":
      return role === "customer"
        ? {
            icon: Clock,
            iconClass: "text-warn",
            headline: `${price} refunded`,
            body: "Refund to your original payment method in 5–7 days",
          }
        : {
            icon: Clock,
            iconClass: "text-warn",
            headline: "Order refunded",
            body: "Escrow returned to the customer",
          };
    case "dispute-frozen":
      return {
        icon: AlertTriangle,
        iconClass: "text-error",
        headline: "Funds frozen",
        body: "Escrow is on hold while the dispute is reviewed",
        cta: {
          label: role === "customer" ? "View dispute" : "Respond to dispute",
          kind: "quiet",
        },
      };
  }
}

export function PaymentBox({
  state,
  role,
  quoteCents,
  currency = "NGN",
  showEscrowExplainer = false,
  onPay,
  onAction,
  className,
}: PaymentBoxProps) {
  const fee = Math.round(quoteCents * FEE_RATE);
  const net = quoteCents - fee;
  const shape = shapeFor(
    state,
    role,
    formatNaira(quoteCents, currency),
    formatNaira(fee, currency),
    formatNaira(net, currency),
  );
  const Icon = shape.icon;

  return (
    <section
      data-state={state}
      data-role={role}
      aria-label="Payment"
      className={clsx(
        "flex flex-col gap-2 rounded-card border border-border bg-bg-elev p-4",
        className,
      )}
    >
      <div className="flex items-center gap-2">
        {Icon ? (
          <Icon
            data-testid={state === "escrow-held" ? "shield-check" : undefined}
            size={18}
            className={clsx("shrink-0", shape.iconClass)}
          />
        ) : null}
        <span className="tnum text-body-lg font-semibold text-text">
          {shape.headline}
        </span>
      </div>

      <p
        data-testid={shape.bodyIsFeeLine ? "fee-line" : undefined}
        className="tnum text-caption text-text-2"
      >
        {shape.body}
      </p>

      {shape.cta ? (
        <Button
          kind={shape.cta.kind}
          loading={shape.cta.loading}
          onClick={
            shape.cta.kind === "gradient-primary"
              ? onPay
              : () => onAction?.(shape.cta!.label)
          }
          className="w-full"
        >
          {shape.cta.label}
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
            confirm delivery. If anything goes wrong, you can open a dispute and
            get refunded.
          </span>
        </div>
      ) : null}
    </section>
  );
}
