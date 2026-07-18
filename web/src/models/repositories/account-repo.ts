// Account + consent repository — api.md §2 (auth & consent group).
import { apiFetch } from "@/lib/api";
import type { Account, ConsentRecord, ProfileLocation } from "../entities/account";

export interface AccountPatch {
  username?: string;
  display_name?: string;
  profile_location?: ProfileLocation | null;
}

export const accountRepo = {
  /** GET /api/v1/me — idempotent upsert on first login (flows/auth.md §3). */
  me: () => apiFetch<Account>("/v1/me"),

  /** PATCH /api/v1/me — username claim/rename (1x/30d) → 409 name_taken. */
  updateMe: (patch: AccountPatch) =>
    apiFetch<Account>("/v1/me", { method: "PATCH", json: patch }),

  /** GET /api/v1/consent */
  consent: () => apiFetch<ConsentRecord[]>("/v1/consent"),

  /** POST /api/v1/consent */
  recordConsent: (document: "tos" | "privacy", version: string) =>
    apiFetch<ConsentRecord>("/v1/consent", {
      method: "POST",
      json: { document, version },
    }),
};
