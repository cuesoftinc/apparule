"use client";

// EarningsSummary + TransactionRow — design.md §8.2b: balance (released) /
// pending (held escrow) cards · TransactionRow kind payout / escrow-held /
// fee-line (10%) · amount tabular + provider ref.
import clsx from "clsx";
import { CreditCard, Info, ShieldCheck } from "lucide-react";
import type { Earnings, EarningsEntry } from "@/models";
import { formatNaira } from "@/lib/format";

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
        {/* Figma master (97:1249): "Available" / "In escrow", green value */}
        <span className="text-caption text-text-2">Available</span>
        <span className="tnum text-title-lg font-bold text-success">
          {formatNaira(earnings.balance_cents, earnings.currency)}
        </span>
      </div>
      <div
        data-testid="pending-card"
        className="flex flex-col gap-1 rounded-card border border-border bg-bg-elev p-4"
      >
        <span className="text-caption text-text-2">In escrow</span>
        <span className="tnum text-title-lg font-bold text-warn">
          {formatNaira(earnings.pending_cents, earnings.currency)}
        </span>
      </div>
    </div>
  );
}

// Figma masters (97:1281): card glyph for payouts, shield for escrow,
// info for the fee line.
const KIND_META = {
  payout: { icon: CreditCard, label: "Payout" },
  escrow_held: { icon: ShieldCheck, label: "Escrow held" },
  fee_line: { icon: Info, label: "Platform fee (10%)" },
} as const;

export interface TransactionRowProps {
  entry: EarningsEntry;
  /**
   * Optional label override — the enriched-landing instances (186:140/150)
   * carry free-text first lines ("Payout to GTBank •••• 4521"); defaults to
   * the derived `{kind} · {order_number}` line.
   */
  label?: string;
  className?: string;
}

export function TransactionRow({
  entry,
  label,
  className,
}: TransactionRowProps) {
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
      <span className="grid size-9 shrink-0 place-items-center rounded-pill border border-border text-text-2">
        <Icon size={16} />
      </span>
      <div className="min-w-0 flex-1">
        <p className="text-body font-semibold text-text">
          {label ?? `${meta.label} · ${entry.order_number}`}
        </p>
        {/* Master (97:1281): ref first, absolute date — "PSK-8842103 ·
            Jul 14"; ref-less fee lines carry the date alone (audit #27). */}
        <p className="truncate text-micro text-text-2">
          {entry.provider_ref ? `${entry.provider_ref} · ` : ""}
          {new Date(entry.created_at).toLocaleDateString("en-NG", {
            month: "short",
            day: "numeric",
          })}
        </p>
      </div>
      {/* Figma master: debits read in the text tokens, credits in success */}
      <span
        className={clsx(
          "tnum shrink-0 text-body font-semibold",
          negative ? "text-text" : "text-success",
        )}
      >
        {negative ? "" : "+"}
        {formatNaira(entry.amount_cents, entry.currency)}
      </span>
    </div>
  );
}
