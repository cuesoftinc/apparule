// DESIGNER_PROFILE + earnings entities — data-model.md §5, §6.5 (PAYOUT),
// pages.md B9 (EarningsSummary + TransactionRow).

export interface DesignerProfile {
  id: string;
  account_id: string;
  username: string;
  display_name: string;
  bio: string;
  avatar_url: string | null;
  /** Paystack provider ref + KYC state. */
  payout_account: {
    provider_ref: string | null;
    bank_name: string | null;
    account_last4: string | null;
    kyc_state: "none" | "pending" | "verified" | "lapsed";
  };
  verified: boolean;
  location: { city: string; state: string; country: string } | null;
  followers_count: number;
  following_count: number;
  posts_count: number;
}

export interface Payout {
  id: string;
  designer_id: string;
  request_id: string;
  amount_cents: number;
  currency: string;
  provider_transfer_ref: string;
  state: "pending" | "paid" | "failed";
  created_at: string;
}

/** One row in the earnings transaction list (pages.md B9). */
export interface EarningsEntry {
  id: string;
  kind: "payout" | "escrow_held" | "fee_line";
  /** Positive amounts in kobo/cents; fee lines are negative. */
  amount_cents: number;
  currency: string;
  /** Human display reference, e.g. "#APR-1058". */
  order_number: string;
  provider_ref: string | null;
  created_at: string;
}

export interface Earnings {
  /** Released balance available for payout withdrawals. */
  balance_cents: number;
  /** Pending escrow (held payments not yet released). */
  pending_cents: number;
  currency: string;
  transactions: EarningsEntry[];
}
