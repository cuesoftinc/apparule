"use client";

// Moderation controllers: the B7a staff queue (open reports + actions) and
// the user-side report flow (SOC-009 — PostCard ⋯ overflow).
import { useCallback, useEffect, useState } from "react";
import type {
  ModerationAction,
  Report,
  ReportReason,
  ReportSubjectKind,
} from "@/models";
import { ApiError } from "@/lib/api";
import { moderationRepo } from "@/models/repositories/moderation-repo";

/** User-side report submission (report post/comment, SOC-009). */
export function useReport() {
  const [submitting, setSubmitting] = useState(false);

  const fileReport = useCallback(
    async (
      subjectKind: ReportSubjectKind,
      subjectId: string,
      reason: ReportReason,
      detail?: string,
    ) => {
      setSubmitting(true);
      try {
        return await moderationRepo.fileReport(
          subjectKind,
          subjectId,
          reason,
          detail,
        );
      } finally {
        setSubmitting(false);
      }
    },
    [],
  );

  return { submitting, fileReport };
}

export function useModeration() {
  const [reports, setReports] = useState<Report[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [forbidden, setForbidden] = useState(false);

  const load = useCallback(
    () =>
      moderationRepo.queue().then(
        (page) => {
          setReports(page.items);
          setError(null);
          setForbidden(false);
          setLoading(false);
        },
        (e: unknown) => {
          if (e instanceof ApiError && e.code === "forbidden") {
            setForbidden(true);
          } else {
            setError(e instanceof Error ? e.message : "Failed to load queue");
          }
          setLoading(false);
        },
      ),
    [],
  );

  useEffect(() => {
    void load();
  }, [load]);

  const reload = useCallback(() => {
    setLoading(true);
    setError(null);
    return load();
  }, [load]);

  const act = useCallback(
    async (reportId: string, action: ModerationAction) => {
      const actioned = await moderationRepo.act(reportId, action);
      // Dismissed rows leave the queue; hide/suspend rows morph in place
      // into the audit-trail state (the queue keeps what moderation did).
      setReports((prev) =>
        action === "dismiss"
          ? prev.filter((r) => r.id !== reportId)
          : prev.map((r) => (r.id === reportId ? actioned : r)),
      );
      return actioned;
    },
    [],
  );

  return { reports, loading, error, forbidden, reload, act };
}
