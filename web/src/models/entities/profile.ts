// Public profile + social-list projections (pages.md B6: profiles ×2,
// followers/following sheets; B2 search-results Designers section).
// api.md §5 has no profile-read group yet — the mock implements these ahead
// of the contract (deviation noted in the stage report).
import type { DesignerProfile } from "./designer";

/** One UserRow in a followers/following/suggestions/search list. */
export interface UserSummary {
  username: string;
  display_name: string;
  avatar_url: string | null;
  verified: boolean;
  /** Only designers can be followed (data-model §5 follow graph). */
  is_designer: boolean;
  /** Meta line for the row (bio lead or location). */
  meta: string | null;
  /** Viewer's follow state — drives the MI-7 Follow/Following morph. */
  viewer_follows: boolean;
}

/** `GET /profiles/{username}` — designer profile or regular-user profile. */
export type PublicProfile =
  | {
      kind: "designer";
      designer: DesignerProfile;
      viewer_follows: boolean;
      viewer_is_self: boolean;
    }
  | {
      kind: "user";
      account: {
        username: string;
        display_name: string;
        avatar_url: string | null;
      };
      viewer_is_self: boolean;
    };

/** Paystack account-resolution result (pages.md B8 resolution states). */
export interface BankResolution {
  account_name: string;
  bank_code: string;
  account_number: string;
}
