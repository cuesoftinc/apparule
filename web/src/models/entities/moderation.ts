// REPORT entity — data-model.md §6.2 (trust & safety, A-6).

export type ReportSubjectKind = "post" | "comment" | "account";
export type ReportReason =
  "spam" | "inappropriate" | "counterfeit" | "harassment" | "other";
export type ModerationAction = "hide_post" | "suspend_account" | "dismiss";

export interface Report {
  id: string;
  reporter: { id: string; username: string };
  subject_kind: ReportSubjectKind;
  subject_id: string;
  /**
   * Preview of the reported content for the queue row — author included so
   * the row title reads "Reported post by @amara.designs" (B7a frame).
   */
  subject_preview: {
    text: string;
    thumb_url: string | null;
    author_username: string | null;
  };
  reason: ReportReason;
  detail: string | null;
  status: "open" | "actioned" | "dismissed";
  /** Audit trail (B7a: "Actioned · hide_comment by @mod · Jul 15, 09:12"). */
  action: ModerationAction | null;
  /** Moderator USERNAME (rendered "@{actioned_by}" in the audit line). */
  actioned_by: string | null;
  actioned_at: string | null;
  created_at: string;
}
