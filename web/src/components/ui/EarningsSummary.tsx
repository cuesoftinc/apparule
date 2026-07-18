"use client";

// EarningsSummary + TransactionRow — design.md §8.2b: balance (released) /
// pending (held escrow) cards · TransactionRow kind payout / escrow-held /
// fee-line (10%) · amount tabular + provider ref.
import clsx from "clsx";
import { ArrowDownToLine, Lock, Percent } from "lucide-react";
import type { Earnings, EarningsEntry } from "@/models";
import { formatAgo, formatNaira } from "@/lib/format";

export interface EarningsSummaryProps {
  earnings: Earnings;
  className?: string;
}

export function EarningsSummary({ earnings, className }: EarningsSummaryProps) {
  return (
    <div className={clsx("grid grid-cols-2 gap-4", className)}>
      <div
        data-testid="balance-card"
        className="flex flex-col gap-1 rounded-card border border-border bg-bg-elev p-4"
      >
        <span className="text-caption text-text-2">Balance (released)</span>
        <span className="tnum text-title-lg font-bold text-text">
          {formatNaira(earnings.balance_cents, earnings.currency)}
        </span>
      </div>
      <div
        data-testid="pending-card"
        className="flex flex-col gap-1 rounded-card border border-border bg-bg-elev p-4"
      >
        <span className="text-caption text-text-2">Pending (escrow)</span>
        <span className="tnum text-title-lg font-bold text-warn">
          {formatNaira(earnings.pending_cents, earnings.currency)}
        </span>
      </div>
    </div>
  );
}

const KIND_META = {
  payout: { icon: ArrowDownToLine, label: "Payout" },
  escrow_held: { icon: Lock, label: "Escrow held" },
  fee_line: { icon: Percent, label: "Platform fee (10%)" },
} as const;

export interface TransactionRowProps {
  entry: EarningsEntry;
  className?: string;
}

export function TransactionRow({ entry, className }: TransactionRowProps) {
  const meta = KIND_META[entry.kind];
  const Icon = meta.icon;
  const negative = entry.amount_cents < 0;
  return (
    <div
      data-kind={entry.kind}
      className={clsx(
        "flex items-center gap-3 border-b border-border py-3",
        className,
      )}
    >
      <span
        className={clsx(
          "grid size-9 shrink-0 place-items-center rounded-pill border border-border",
          entry.kind === "payout" && "text-success",
          entry.kind === "escrow_held" && "text-warn",
          entry.kind === "fee_line" && "text-text-2",
        )}
      >
        <Icon size={16} />
      </span>
      <div className="min-w-0 flex-1">
        <p className="text-body font-semibold text-text">
          {meta.label} · {entry.order_number}
        </p>
        <p className="truncate text-micro text-text-2">
          {formatAgo(entry.created_at)}
          {entry.provider_ref ? ` · ${entry.provider_ref}` : ""}
        </p>
      </div>
      <span
        className={clsx(
          "tnum shrink-0 text-body font-semibold",
          negative
            ? "text-text-2"
            : entry.kind === "escrow_held"
              ? "text-warn"
              : "text-success",
        )}
      >
        {negative ? "" : "+"}
        {formatNaira(entry.amount_cents, entry.currency)}
      </span>
    </div>
  );
}
