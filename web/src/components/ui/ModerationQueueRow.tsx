"use client";

// ModerationQueueRow — design.md §8.2b: subject preview (post/comment thumb
// + reporter context) · reason · actions hide_post / suspend_account /
// dismiss · state open / actioned (audit: actioned_by).
import clsx from "clsx";
import Image from "next/image";
import type { ModerationAction, Report } from "@/models";
import { formatAgo } from "@/lib/format";
import { Button } from "./Button";

export interface ModerationQueueRowProps {
  report: Report;
  onAction?: (action: ModerationAction) => void;
  className?: string;
}

export function ModerationQueueRow({
  report,
  onAction,
  className,
}: ModerationQueueRowProps) {
  const open = report.status === "open";
  return (
    <div
      data-state={open ? "open" : "actioned"}
      className={clsx(
        "flex flex-col gap-3 rounded-card border border-border bg-bg-elev p-4",
        !open && "opacity-70",
        className,
      )}
    >
      <div className="flex items-start gap-3">
        {report.subject_preview.thumb_url ? (
          <span className="relative size-12 shrink-0 overflow-hidden rounded-card bg-border/40">
            <Image
              src={report.subject_preview.thumb_url}
              alt=""
              fill
              sizes="48px"
              className="object-cover"
            />
          </span>
        ) : null}
        <div className="min-w-0 flex-1">
          <p className="line-clamp-2 text-body text-text">
            {report.subject_preview.text}
          </p>
          <p className="mt-0.5 text-caption text-text-2">
            {report.subject_kind} · reported by {report.reporter.username} ·{" "}
            {formatAgo(report.created_at)}
          </p>
        </div>
        <span className="shrink-0 rounded-pill border border-error/40 bg-error/10 px-2.5 py-0.5 text-micro font-semibold text-error">
          {report.reason}
        </span>
      </div>
      {open ? (
        <div className="flex gap-2">
          <Button kind="destructive" size="sm" onClick={() => onAction?.("hide_post")}>
            Hide post
          </Button>
          <Button kind="quiet" size="sm" onClick={() => onAction?.("suspend_account")}>
            Suspend account
          </Button>
          <Button kind="quiet" size="sm" onClick={() => onAction?.("dismiss")}>
            Dismiss
          </Button>
        </div>
      ) : (
        <p data-testid="audit-line" className="text-micro text-text-2">
          {report.status} · by {report.actioned_by ?? "moderator"}
        </p>
      )}
    </div>
  );
}
