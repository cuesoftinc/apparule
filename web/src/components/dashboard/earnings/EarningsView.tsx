"use client";

// B9 — Earnings & payouts (Figma 210:3): "Earnings & payouts" headline with
// the balance explainer · EarningsSummary cards (released / pending escrow)
// · payout-account card (bank ••• last4 — holder, Verified chip, fee note,
// change → B8) · Recent activity TransactionRow list (payouts, escrow-held,
// itemized 10% fee lines, provider refs). Render-only over useEarnings.
import Link from "next/link";
import { useAuth } from "@/controllers/auth/AuthContext";
import { useEarnings } from "@/controllers/use-profile";
import {
  EarningsSummary,
  TransactionRow,
} from "@/components/ui/EarningsSummary";
import { EmptyState } from "@/components/ui/EmptyState";
import { Skeleton } from "@/components/ui/Skeleton";

export function EarningsView() {
  const { account } = useAuth();
  const { earnings, loading, error, errorCode, payoutAccount, reload } =
    useEarnings(account?.designer.enabled ? account.username : null);

  return (
    <div className="mx-auto flex max-w-3xl flex-col gap-6 px-4 py-6">
      <header>
        <h1 className="text-title-lg font-bold text-text">
          Earnings &amp; payouts
        </h1>
        <p className="text-body text-text-2">
          Balance is released payouts. Pending is escrow held on open orders —
          it releases when delivery is confirmed.
        </p>
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
          <div className="grid gap-4 md:grid-cols-[1fr_auto]">
            <section aria-label="Balances">
              <EarningsSummary earnings={earnings} />
            </section>
            {/* Figma 210:3: payout-account card with the Verified chip, fee
                note, and the change link → B8. */}
            <section
              aria-labelledby="payout-account-h"
              data-testid="payout-status-chip"
              className="flex max-w-xs flex-col gap-1 rounded-card border border-border bg-bg-elev p-4"
            >
              <h2
                id="payout-account-h"
                className="text-body font-semibold text-text"
              >
                Payout account
              </h2>
              {payoutAccount?.provider_ref ? (
                <>
                  <p className="text-body text-text">
                    {payoutAccount.bank_name} ••• {payoutAccount.account_last4}
                    {"  "}
                    <span
                      className={
                        payoutAccount.kyc_state === "verified"
                          ? "text-caption font-semibold text-success"
                          : "text-caption font-semibold text-warn"
                      }
                    >
                      {payoutAccount.kyc_state === "verified"
                        ? "Verified"
                        : payoutAccount.kyc_state === "lapsed"
                          ? "Lapsed"
                          : "Pending"}
                    </span>
                  </p>
                  <p className="text-caption text-text-2">
                    Payouts arrive within 1 business day of release · fee 10%
                    per order
                  </p>
                  <Link
                    href="/dashboard/designer/onboarding"
                    className="text-caption font-semibold text-link"
                  >
                    Change account →
                  </Link>
                </>
              ) : (
                <>
                  <p className="text-caption text-text-2">
                    No payout account yet — requests stay locked until one is
                    verified.
                  </p>
                  <Link
                    href="/dashboard/designer/onboarding"
                    className="text-caption font-semibold text-link"
                  >
                    Add account →
                  </Link>
                </>
              )}
            </section>
          </div>
          <section aria-labelledby="transactions-h">
            <h2
              id="transactions-h"
              className="pb-2 text-body font-semibold text-text"
            >
              Recent activity
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
