"use client";

// B7a — Moderation queue (staff only, A-6): open reports with subject
// preview + reporter context; actions hide_post / suspend_account /
// dismiss; audit trail via REPORT.actioned_by. Render-only over
// useModeration.
import { useModeration } from "@/controllers/use-moderation";
import { Banner } from "@/components/ui/Banner";
import { EmptyState } from "@/components/ui/EmptyState";
import { ModerationQueueRow } from "@/components/ui/ModerationQueueRow";
import { Skeleton } from "@/components/ui/Skeleton";
import { useToasts } from "../toast-context";

export function ModerationView() {
  const { reports, loading, error, forbidden, reload, act } = useModeration();
  const { showToast } = useToasts();

  return (
    <div className="mx-auto flex max-w-2xl flex-col gap-4 px-4 py-6">
      <header className="flex flex-col gap-4">
        <h1 className="text-title-lg font-bold text-text">Moderation queue</h1>
        {/* Figma 182:1223: audit-log notice as an info Banner. */}
        <Banner tone="info">
          Every action here is recorded in the audit log.
        </Banner>
      </header>

      {loading ? (
        <div aria-busy="true">
          <Skeleton kind="card" />
        </div>
      ) : forbidden ? (
        <p role="alert" className="py-12 text-center text-body text-text-2">
          Moderation is staff-only.
        </p>
      ) : error ? (
        <EmptyState
          context="notifications"
          line="The queue couldn't load — try again."
          ctaLabel="Retry"
          onCta={() => void reload()}
        />
      ) : reports.length === 0 ? (
        <EmptyState
          context="notifications"
          line="No open reports — the queue is clear."
        />
      ) : (
        <ul className="flex flex-col gap-3" data-testid="moderation-queue">
          {reports.map((report) => (
            <li key={report.id}>
              <ModerationQueueRow
                report={report}
                onAction={(action) =>
                  act(report.id, action).then(
                    () =>
                      showToast({
                        kind: "success",
                        message:
                          action === "dismiss"
                            ? "Report dismissed"
                            : action === "hide_post"
                              ? "Content hidden"
                              : "Account suspended",
                      }),
                    () =>
                      showToast({
                        kind: "error",
                        message: "Action failed — try again",
                      }),
                  )
                }
              />
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
