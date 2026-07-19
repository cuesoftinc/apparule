// NOTIFICATION entity — data-model.md §6.4 (90d retention; unread badge
// derives from read_at IS NULL) + NotificationRow kinds (design.md §8.2b).

export type NotificationKind =
  "like" | "follow" | "comment" | "quote" | "status_change" | "payout";

export interface Notification {
  id: string;
  account_id: string;
  kind: NotificationKind;
  /** order/post id the row references. */
  payload_ref: string;
  /** Display line, e.g. "amara.designs quoted your request". */
  text: string;
  actor: { username: string; avatar_url: string | null } | null;
  /** Post thumbnail for like/comment rows (NotificationRow trailing slot). */
  thumb_url: string | null;
  read_at: string | null;
  created_at: string;
}
