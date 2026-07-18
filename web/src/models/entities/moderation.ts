// REPORT entity — data-model.md §6.2 (trust & safety, A-6).

export type ReportSubjectKind = "post" | "comment" | "account";
export type ReportReason =
  | "spam"
  | "inappropriate"
  | "counterfeit"
  | "harassment"
  | "other";
export type ModerationAction = "hide_post" | "suspend_account" | "dismiss";

export interface Report {
  id: string;
  reporter: { id: string; username: string };
  subject_kind: ReportSubjectKind;
  subject_id: string;
  /** Preview of the reported content for the queue row. */
  subject_preview: { text: string; thumb_url: string | null };
  reason: ReportReason;
  detail: string | null;
  status: "open" | "actioned" | "dismissed";
  actioned_by: string | null;
  created_at: string;
}
