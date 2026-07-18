// Trust & safety repository — api.md §5 (reports, blocks, moderation queue).
import { apiFetch, type Page } from "@/lib/api";
import type {
  ModerationAction,
  Report,
  ReportReason,
  ReportSubjectKind,
} from "../entities/moderation";

export const moderationRepo = {
  /** POST /api/v1/reports */
  fileReport: (
    subjectKind: ReportSubjectKind,
    subjectId: string,
    reason: ReportReason,
    detail?: string,
  ) =>
    apiFetch<Report>("/v1/reports", {
      method: "POST",
      json: {
        subject_kind: subjectKind,
        subject_id: subjectId,
        reason,
        detail,
      },
    }),

  /** POST/DELETE /api/v1/blocks/{account} — silent (data-model §6.2). */
  block: (account: string) =>
    apiFetch<void>(`/v1/blocks/${account}`, { method: "POST" }),
  unblock: (account: string) =>
    apiFetch<void>(`/v1/blocks/${account}`, { method: "DELETE" }),

  /** GET /api/v1/moderation/queue — moderator only. */
  queue: (cursor?: string) =>
    apiFetch<Page<Report>>(
      `/v1/moderation/queue${cursor ? `?cursor=${cursor}` : ""}`,
    ),

  /** POST /api/v1/moderation/reports/{id}/action */
  act: (reportId: string, action: ModerationAction) =>
    apiFetch<Report>(`/v1/moderation/reports/${reportId}/action`, {
      method: "POST",
      json: { action },
    }),
};
