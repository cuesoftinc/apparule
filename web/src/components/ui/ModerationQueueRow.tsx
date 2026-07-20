"use client";

// ModerationQueueRow — design.md §8.2b: subject preview (post/comment thumb
// + reporter context) · reason · actions hide_post / suspend_account /
// dismiss · state open / actioned (audit line: effective action + @moderator
// + timestamp, B7a canvas: "Actioned · hide_comment by @mod.sarah · Jul 15,
// 09:12").
import clsx from "clsx";
import Image from "next/image";
import { format } from "date-fns";
import type { ModerationAction, Report } from "@/models";
import { formatAgoPhrase } from "@/lib/format";
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
  // Audit line shows the EFFECTIVE action: hide_post on a comment subject
  // hides the comment, so it reads "hide_comment" (canvas idiom).
  const effectiveAction =
    report.action === "hide_post" && report.subject_kind === "comment"
      ? "hide_comment"
      : report.action;
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
        {/* Figma master (93:1219): "Reported post/comment" headline (with
            the content author when known — "Reported post by @amara.designs"),
            the excerpt + reporter in the meta line, warn-tinted Spam pill. */}
        <div className="min-w-0 flex-1">
          <p className="text-body font-semibold text-text">
            Reported {report.subject_kind}
            {report.subject_preview.author_username
              ? ` by @${report.subject_preview.author_username}`
              : ""}
          </p>
          <p className="mt-0.5 line-clamp-2 text-caption text-text-2">
            “{report.subject_preview.text}” · Reported by @
            {report.reporter.username} · {formatAgoPhrase(report.created_at)}
          </p>
        </div>
        <span className="shrink-0 rounded-pill bg-warn/14 px-2 py-0.5 text-micro font-semibold capitalize text-warn">
          {report.reason}
        </span>
      </div>
      {open ? (
        <div className="flex flex-wrap gap-2">
          <Button
            kind="quiet"
            size="sm"
            onClick={() => onAction?.("hide_post")}
          >
            {report.subject_kind === "comment" ? "Hide comment" : "Hide post"}
          </Button>
          <Button
            kind="destructive"
            size="sm"
            onClick={() => onAction?.("suspend_account")}
          >
            Suspend account
          </Button>
          <Button kind="quiet" size="sm" onClick={() => onAction?.("dismiss")}>
            Dismiss
          </Button>
        </div>
      ) : (
        <p data-testid="audit-line" className="text-micro text-text-2">
          Actioned{effectiveAction ? ` · ${effectiveAction}` : ""} by @
          {report.actioned_by?.username ?? "moderator"}
          {report.actioned_at
            ? ` · ${format(new Date(report.actioned_at), "MMM d, HH:mm")}`
            : ""}
        </p>
      )}
    </div>
  );
}
