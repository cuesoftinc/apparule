// ACCOUNT + consent entities — data-model.md §2.

/** Optional, self-attested location (X-10 tier 1). Sensitive PII — never logged. */
export interface ProfileLocation {
  city: string;
  state: string;
  country: string;
}

export interface ConsentRecord {
  document: "tos" | "privacy";
  version: string;
  accepted_at: string;
}

/**
 * Per-event notification toggles (pages.md B7 Notifications sub-screen).
 * W3 addition ahead of the api.md contract — carried on the account so
 * `PATCH /me` persists them (deviation noted in the stage report).
 */
export interface NotificationPrefs {
  quotes: boolean;
  order_status: boolean;
  social: boolean;
  payouts: boolean;
}

export interface Account {
  id: string;
  firebase_uid: string;
  email: string;
  /** unique (case-insensitive), 3-30 chars [a-z0-9._]; rename max 1x/30d */
  username: string;
  display_name: string;
  avatar_url: string | null;
  profile_location: ProfileLocation | null;
  deletion_state: "active" | "deletion_pending";
  designer: {
    enabled: boolean;
    kyc_complete: boolean;
  };
  /** Staff flag gates the B7a moderation queue (A-6). W3 mock-ahead addition. */
  is_staff: boolean;
  notification_prefs: NotificationPrefs;
  consent: ConsentRecord[];
  created_at: string;
}
