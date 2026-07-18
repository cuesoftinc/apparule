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

/** Next action per role per state (order-lifecycle.md §2 permissions). */
const NEXT_ACTION: Record<RequestCardRole, Partial<Record<OrderStatus, string>>> = {
  customer: {
    quoted: "Pay",
    shipped: "Confirm delivery",
    delivered: "View order",
  },
  designer: {
    requested: "Quote",
    paid: "Start work",
    in_progress: "Mark shipped",
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
  const action = NEXT_ACTION[role][order.status];
  const amount = order.quote_cents ?? order.budget_cents;

  return (
    <div
      data-role={role}
      data-status={order.status}
      className={clsx(
        "flex items-center gap-4 rounded-card border border-border bg-bg-elev p-4",
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
      <div className="min-w-0 flex-1">
        <div className="flex items-center gap-2">
          {/* 1-line truncation keeps the price visible (as-built fix) */}
          <button
            type="button"
            onClick={onOpen}
            className="min-w-0 truncate text-left text-body font-semibold text-text"
          >
            {order.post.caption}
          </button>
        </div>
        <p className="truncate text-caption text-text-2">
          #{order.order_number} · {role === "customer" ? "by" : "for"}{" "}
          {counterparty}
        </p>
        <div className="mt-1.5 flex items-center gap-3">
          <StatusPill status={order.status} />
          {amount !== null ? (
            <span className="tnum text-body font-semibold text-text">
              {formatNaira(amount, order.currency)}
            </span>
          ) : (
            <span className="text-caption text-text-2">quote on request</span>
          )}
        </div>
      </div>
      {action ? (
        <Button
          kind={action === "Pay" ? "gradient-primary" : "quiet"}
          size="sm"
          onClick={() => onAction?.(action)}
          className="shrink-0"
        >
          {action}
        </Button>
      ) : null}
    </div>
  );
}
