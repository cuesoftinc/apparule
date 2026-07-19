"use client";

// B9 — Earnings & payouts (designer): EarningsSummary cards (released /
// pending escrow) + TransactionRow list (payouts, escrow-held, itemized 10%
// fee lines, provider refs); payout-account status chip → B8 to fix.
// Render-only over useEarnings.
import Link from "next/link";
import { useAuth } from "@/controllers/auth/AuthContext";
import { useEarnings } from "@/controllers/use-profile";
import {
  EarningsSummary,
  TransactionRow,
} from "@/components/ui/EarningsSummary";
import { EmptyState } from "@/components/ui/EmptyState";
import { Skeleton } from "@/components/ui/Skeleton";
import { StatusPill } from "@/components/ui/StatusPill";

export function EarningsView() {
  const { account } = useAuth();
  const { earnings, loading, error, errorCode, reload } = useEarnings();

  return (
    <div className="mx-auto flex max-w-2xl flex-col gap-6 px-4 py-6">
      <header className="flex items-center justify-between gap-3">
        <h1 className="text-title-lg font-bold text-text">Earnings</h1>
        {account?.designer.enabled ? (
          <Link
            href="/dashboard/designer/onboarding"
            aria-label="Payout account status"
            data-testid="payout-status-chip"
          >
            <StatusPill
              status={account.designer.kyc_complete ? "fresh" : "stale"}
            />
          </Link>
        ) : null}
      </header>

      {loading ? (
        <div aria-busy="true">
          <Skeleton kind="card" />
        </div>
      ) : errorCode === "designer_profile_required" ? (
        <EmptyState
          context="orders"
          line="Earnings are for designer profiles — become a designer to start earning."
          ctaLabel="Become a designer"
          onCta={() =>
            window.location.assign("/dashboard/designer/onboarding")
          }
        />
      ) : error || !earnings ? (
        <EmptyState
          context="orders"
          line="Earnings couldn't load — try again."
          ctaLabel="Retry"
          onCta={() => void reload()}
        />
      ) : (
        <>
          <section aria-label="Balances">
            <EarningsSummary earnings={earnings} />
          </section>
          <section aria-labelledby="transactions-h">
            <h2
              id="transactions-h"
              className="pb-2 text-body font-semibold text-text-2"
            >
              Transactions
            </h2>
            {earnings.transactions.length === 0 ? (
              <EmptyState
                context="orders"
                line="Payouts and escrow holds will itemize here — publish outfits to get commissioned."
                ctaLabel="Create a post"
                onCta={() => window.location.assign("/dashboard/create")}
              />
            ) : (
              <ul data-testid="transactions-list">
                {earnings.transactions.map((entry) => (
                  <li key={entry.id}>
                    <TransactionRow entry={entry} />
                  </li>
                ))}
              </ul>
            )}
          </section>
        </>
      )}
    </div>
  );
}
