"use client";

// RequestCard — design.md §3/§8.2: outfit thumb · status pill (×10 states,
// MI-14) · designer/customer (role view) · price · next-action button.
// As-built fix (2026-07-18 QA): the title truncates to 1 line so the price
// is always visible.
import clsx from "clsx";
import Image from "next/image";
import type { CommissionRequest, OrderStatus } from "@/models";
import { formatNaira } from "@/lib/format";
import { Button } from "./Button";
import { StatusPill } from "./StatusPill";

export type RequestCardRole = "customer" | "designer";

/** Next action per role per state — the full ×10 matrix drawn in the
 * RequestCard masters (53:614); `primary` actions paint the gradient. */
const NEXT_ACTION: Record<
  RequestCardRole,
  Partial<Record<OrderStatus, { label: string; primary?: boolean }>>
> = {
  customer: {
    requested: { label: "Cancel request" },
    quoted: { label: "Pay", primary: true },
    paid: { label: "View order" },
    in_progress: { label: "View updates" },
    shipped: { label: "Confirm delivery", primary: true },
    delivered: { label: "View order" },
    refunded: { label: "View details" },
    declined: { label: "Find similar" },
    disputed: { label: "View dispute" },
    cancelled: { label: "View details" },
  },
  designer: {
    requested: { label: "Send quote", primary: true },
    quoted: { label: "Edit quote" },
    paid: { label: "Start work", primary: true },
    in_progress: { label: "Mark shipped", primary: true },
    shipped: { label: "Add tracking" },
    delivered: { label: "View payout" },
    refunded: { label: "View details" },
    declined: { label: "View request" },
    disputed: { label: "Respond", primary: true },
    cancelled: { label: "View details" },
  },
};

export interface RequestCardProps {
  order: CommissionRequest;
  role: RequestCardRole;
  onOpen?: () => void;
  onAction?: (actionLabel: string) => void;
  className?: string;
}

export function RequestCard({
  order,
  role,
  onOpen,
  onAction,
  className,
}: RequestCardProps) {
  const counterparty =
    role === "customer" ? order.designer.username : order.customer.username;
  let action = NEXT_ACTION[role][order.status];
  // "Add tracking" only makes sense while tracking is missing — once the
  // shipment carries a ref the row's shortcut is just "View order".
  if (
    role === "designer" &&
    order.status === "shipped" &&
    order.tracking !== null
  ) {
    action = { label: "View order" };
  }
  const amount = order.quote_cents ?? order.budget_cents;
  const price = amount !== null ? formatNaira(amount, order.currency) : null;

  return (
    <div
      data-role={role}
      data-status={order.status}
      className={clsx(
        // Figma master (53:614): p 12 / gap 12, 64px thumb, title/meta/price
        // column, pill + action stacked at the trailing edge.
        "flex items-start gap-3 rounded-card border border-border bg-bg-elev p-3",
        className,
      )}
    >
      <button
        type="button"
        onClick={onOpen}
        aria-label={`Open order ${order.order_number}`}
        className="relative size-16 shrink-0 overflow-hidden rounded-card bg-border/40"
      >
        <Image
          src={order.post.thumb_url}
          alt={order.post.caption}
          fill
          sizes="64px"
          className="object-cover"
        />
      </button>
      <div className="flex min-w-0 flex-1 flex-col gap-[2px]">
        {/* 1-line truncation keeps the price visible (as-built fix) */}
        <button
          type="button"
          onClick={onOpen}
          className="min-w-0 truncate text-left text-body font-semibold text-text"
        >
          {order.post.caption}
        </button>
        <p className="truncate text-caption text-text-2">
          #{order.order_number} · {role === "customer" ? "by" : "for"}{" "}
          {counterparty}
        </p>
        {price !== null ? (
          <span className="tnum text-body font-semibold text-text">
            {price}
          </span>
        ) : (
          <span className="text-caption text-text-2">quote on request</span>
        )}
      </div>
      <div className="flex shrink-0 flex-col items-end gap-2">
        <StatusPill status={order.status} />
        {action ? (
          <Button
            kind={action.primary ? "gradient-primary" : "quiet"}
            size="sm"
            onClick={() => onAction?.(action.label)}
          >
            {action.label === "Pay" && price !== null
              ? `Pay ${price}`
              : action.label}
          </Button>
        ) : null}
      </div>
    </div>
  );
}
