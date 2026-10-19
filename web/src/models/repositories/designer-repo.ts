// Designer profile + earnings repository — api.md §5 (Designer group),
// pages.md B8/B9; search/suggested back the B2/B1 designer lists
// (mock-ahead-of-contract).
import { env } from "@/config/env";
import { ApiError, apiFetch, type Page } from "@/lib/api";
import type { DesignerProfile, Earnings } from "../entities/designer";
import type { BankResolution, UserSummary } from "../entities/profile";
import { pollUntil } from "./upload";

type PayoutAccount = DesignerProfile["payout_account"] & {
  account_name?: string | null;
  reason?: string | null;
};

const REASONS: Record<string, string> = {
  name_mismatch: "The account name doesn't match your profile name",
  account_invalid: "Could not resolve that account number",
  provider_error: "Bank verification is unavailable — try again shortly",
};

/**
 * Real backend (pages.md B8): verification is asynchronous through
 * api/commerce — submit, then poll until the account is verified or not.
 */
async function verifyOnBackend(
  bankCode: string,
  accountNumber: string,
): Promise<PayoutAccount> {
  await apiFetch<PayoutAccount>("/v1/designer/payout-account", {
    method: "POST",
    json: { bank_code: bankCode, account_number: accountNumber },
  });
  const account = await pollUntil(
    () => apiFetch<PayoutAccount>("/v1/designer/payout-account"),
    (a) => a.kyc_state !== "pending",
    { intervalMs: 1500, timeoutMs: 60_000 },
  );
  if (account.kyc_state !== "verified") {
    const reason = account.reason ?? "account_invalid";
    throw new ApiError(
      "bank_resolution_failed",
      REASONS[reason] ?? REASONS.account_invalid,
      422,
      { reason },
    );
  }
  return account;
}

export const designerRepo = {
  /** POST /api/v1/designer-profile — enable + start Paystack KYC. */
  enable: (displayName: string, bio?: string) =>
    apiFetch<DesignerProfile>("/v1/designer-profile", {
      method: "POST",
      json: { display_name: displayName, bio },
    }),

  /** POST /api/v1/designer/payout-account/resolve — scripted resolution
   * states (pages.md B8: resolving → resolved name / mismatch error). */
  resolveBank: async (
    bankCode: string,
    accountNumber: string,
  ): Promise<BankResolution> => {
    if (env.testMode) {
      return apiFetch<BankResolution>("/v1/designer/payout-account/resolve", {
        method: "POST",
        json: { bank_code: bankCode, account_number: accountNumber },
      });
    }
    const account = await verifyOnBackend(bankCode, accountNumber);
    return {
      account_name: account.account_name ?? "",
      bank_code: bankCode,
      account_number: accountNumber,
    };
  },

  /** POST /api/v1/designer/payout-account — attach the resolved account. */
  attachPayoutAccount: (bankCode: string, accountNumber: string) =>
    env.testMode
      ? apiFetch<DesignerProfile["payout_account"]>(
          "/v1/designer/payout-account",
          {
            method: "POST",
            json: { bank_code: bankCode, account_number: accountNumber },
          },
        )
      : // Resolving already verified and attached it (commerce created the
        // transfer recipient); read the stored account.
        apiFetch<DesignerProfile["payout_account"]>(
          "/v1/designer/payout-account",
        ),

  /** GET /api/v1/designer/earnings — balance + payout history. */
  earnings: () => apiFetch<Earnings>("/v1/designer/earnings"),

  /** GET /api/v1/designers?q= — B2 search-results Designers section. */
  search: (q: string) =>
    apiFetch<Page<UserSummary>>(`/v1/designers?q=${encodeURIComponent(q)}`),

  /** GET /api/v1/designers/suggested — B1 right-column suggestions. */
  suggested: () => apiFetch<Page<UserSummary>>("/v1/designers/suggested"),
};
