"use client";

// SessionRow — design.md §8.2b: context history (date + method chip +
// values + delete) / picker (radio select + freshness warning fresh /
// aging / stale) · state default / selected.
import clsx from "clsx";
import { Trash2 } from "lucide-react";
import type { MeasurementSession } from "@/models";
import { freshnessOf } from "@/models";
import { formatCm } from "@/lib/format";
import { humanizeMeasureName } from "./ManualMeasureRow";
import { StatusPill } from "./StatusPill";

export type SessionRowContext = "history" | "picker";

export interface SessionRowProps {
  session: MeasurementSession;
  context?: SessionRowContext;
  selected?: boolean;
  onSelect?: () => void;
  onDelete?: () => void;
  className?: string;
}

const METHOD_LABEL: Record<string, string> = {
  mediapipe_2d: "scan",
  mediapipe_2d_v2: "scan",
  smpl_v1: "scan (3D)",
  manual: "manual",
};

export function SessionRow({
  session,
  context = "history",
  selected = false,
  onSelect,
  onDelete,
  className,
}: SessionRowProps) {
  const freshness = freshnessOf(session.created_at);
  const values = session.measurements
    .slice(0, 3)
    .map((m) => `${humanizeMeasureName(m.name)} ${formatCm(m.value_cm)}`)
    .join(" · ");

  const body = (
    <>
      {context === "picker" ? (
        <span
          data-testid="picker-radio"
          className={clsx(
            "grid size-5 shrink-0 place-items-center rounded-pill border-2",
            selected ? "border-accent-start" : "border-border",
          )}
        >
          {selected ? (
            <span className="size-2.5 rounded-pill bg-accent-gradient" />
          ) : null}
        </span>
      ) : null}
      <div className="min-w-0 flex-1">
        <div className="flex items-center gap-2">
          <time
            dateTime={session.created_at}
            className="text-body font-semibold text-text"
          >
            {new Date(session.created_at).toLocaleDateString("en-NG", {
              day: "numeric",
              month: "short",
              year: "numeric",
            })}
          </time>
          <span className="rounded-pill border border-border px-2 py-0.5 text-micro font-semibold text-text-2">
            {METHOD_LABEL[session.method] ?? session.method}
          </span>
          {context === "picker" ? <StatusPill status={freshness} /> : null}
        </div>
        <p className="tnum mt-0.5 truncate text-caption text-text-2">{values}</p>
        {context === "picker" && freshness !== "fresh" ? (
          <p data-testid="freshness-warning" className="mt-1 text-micro text-warn">
            {freshness === "aging"
              ? "Measured over a month ago — consider retaking"
              : "Over 90 days old — retake recommended before ordering"}
          </p>
        ) : null}
      </div>
    </>
  );

  if (context === "picker") {
    return (
      <button
        type="button"
        role="radio"
        aria-checked={selected}
        onClick={onSelect}
        data-context={context}
        className={clsx(
          "flex w-full items-center gap-3 rounded-card border p-4 text-left",
          "transition-colors duration-120 ease-standard motion-reduce:transition-none",
          selected ? "border-accent-start" : "border-border",
          className,
        )}
      >
        {body}
      </button>
    );
  }

  return (
    <div
      data-context={context}
      className={clsx(
        "flex w-full items-center gap-3 border-b border-border p-4",
        className,
      )}
    >
      {body}
      <button
        type="button"
        aria-label="Delete session"
        onClick={onDelete}
        className="shrink-0 text-text-2 hover:text-error"
      >
        <Trash2 size={18} />
      </button>
    </div>
  );
}
