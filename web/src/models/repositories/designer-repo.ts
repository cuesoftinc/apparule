// Designer profile + earnings repository — api.md §5 (Designer group),
// pages.md B8/B9; search/suggested back the B2/B1 designer lists
// (mock-ahead-of-contract).
import { apiFetch, type Page } from "@/lib/api";
import type { DesignerProfile, Earnings } from "../entities/designer";
import type { BankResolution, UserSummary } from "../entities/profile";

export const designerRepo = {
  /** POST /api/v1/designer-profile — enable + start Paystack KYC. */
  enable: (displayName: string, bio?: string) =>
    apiFetch<DesignerProfile>("/v1/designer-profile", {
      method: "POST",
      json: { display_name: displayName, bio },
    }),

  /** POST /api/v1/designer/payout-account/resolve — scripted resolution
   * states (pages.md B8: resolving → resolved name / mismatch error). */
  resolveBank: (bankCode: string, accountNumber: string) =>
    apiFetch<BankResolution>("/v1/designer/payout-account/resolve", {
      method: "POST",
      json: { bank_code: bankCode, account_number: accountNumber },
    }),

  /** POST /api/v1/designer/payout-account — attach the resolved account. */
  attachPayoutAccount: (bankCode: string, accountNumber: string) =>
    apiFetch<DesignerProfile["payout_account"]>("/v1/designer/payout-account", {
      method: "POST",
      json: { bank_code: bankCode, account_number: accountNumber },
    }),

  /** GET /api/v1/designer/earnings — balance + payout history. */
  earnings: () => apiFetch<Earnings>("/v1/designer/earnings"),

  /** GET /api/v1/designers?q= — B2 search-results Designers section. */
  search: (q: string) =>
    apiFetch<Page<UserSummary>>(`/v1/designers?q=${encodeURIComponent(q)}`),

  /** GET /api/v1/designers/suggested — B1 right-column suggestions. */
  suggested: () => apiFetch<Page<UserSummary>>("/v1/designers/suggested"),
};
