// Account + consent repository — api.md §2 (auth & consent group) plus the
// B7 Account & data rights endpoints (export / delete-all).
import { apiFetch } from "@/lib/api";
import type {
  Account,
  ConsentRecord,
  NotificationPrefs,
  ProfileLocation,
} from "../entities/account";

export interface AccountPatch {
  username?: string;
  display_name?: string;
  profile_location?: ProfileLocation | null;
  notification_prefs?: Partial<NotificationPrefs>;
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

  /** GET /api/v1/me/export — "Download my data" (data-model §4 rights). */
  exportData: () => apiFetch<Record<string, unknown>>("/v1/me/export"),

  /** POST /api/v1/me/deletion — delete-all request (confirm-gated in UI). */
  requestDeletion: () =>
    apiFetch<Account>("/v1/me/deletion", { method: "POST" }),
};
