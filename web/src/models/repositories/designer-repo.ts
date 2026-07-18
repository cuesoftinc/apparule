// Designer profile + earnings repository — api.md §5 (Designer group),
// pages.md B8/B9.
import { apiFetch } from "@/lib/api";
import type { DesignerProfile, Earnings } from "../entities/designer";

export const designerRepo = {
  /** POST /api/v1/designer-profile — enable + start Paystack KYC. */
  enable: (displayName: string, bio?: string) =>
    apiFetch<DesignerProfile>("/v1/designer-profile", {
      method: "POST",
      json: { display_name: displayName, bio },
    }),

  /** POST /api/v1/designer/payout-account — bank resolution via Paystack. */
  attachPayoutAccount: (bankCode: string, accountNumber: string) =>
    apiFetch<DesignerProfile["payout_account"]>("/v1/designer/payout-account", {
      method: "POST",
      json: { bank_code: bankCode, account_number: accountNumber },
    }),

  /** GET /api/v1/designer/earnings — balance + payout history. */
  earnings: () => apiFetch<Earnings>("/v1/designer/earnings"),
};
