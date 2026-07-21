"use client";

// Banner / InlineAlert — design.md §8.2b: tone info / warn / error /
// success · persistent / dismissable · action-link slot (Retry, support,
// explainer). Used for KYC-lapse, offline retry, consent notices.
import { useState } from "react";
import clsx from "clsx";
import { AlertTriangle, CheckCircle2, Info, X } from "lucide-react";

export type BannerTone = "info" | "warn" | "error" | "success";

export interface BannerProps {
  tone?: BannerTone;
  children: React.ReactNode;
  /** Renders the trailing ✕; the banner unmounts itself + notifies. */
  dismissable?: boolean;
  onDismiss?: () => void;
  /** Action-link slot. */
  actionLabel?: string;
  onAction?: () => void;
  className?: string;
}

// Figma master (95:1220): info=circled-i, warn/error=triangle, success=check.
const TONE_ICON: Record<BannerTone, typeof Info> = {
  info: Info,
  warn: AlertTriangle,
  error: AlertTriangle,
  success: CheckCircle2,
};

// Action links bind to the tone token (Learn more=link, Re-verify=warn…) —
// readable text on the /10 tint, so warn/success bind their AA `-text`
// variants (§2); link/error base values already clear 4.5 there.
const TONE_ACTION: Record<BannerTone, string> = {
  info: "text-link",
  warn: "text-warn-text",
  error: "text-error",
  success: "text-success-text",
};

export function Banner({
  tone = "info",
  children,
  dismissable = false,
  onDismiss,
  actionLabel,
  onAction,
  className,
}: BannerProps) {
  const [dismissed, setDismissed] = useState(false);
  if (dismissed) return null;
  const Icon = TONE_ICON[tone];
  return (
    <div
      role={tone === "error" ? "alert" : "status"}
      data-tone={tone}
      className={clsx(
        "flex items-start gap-3 rounded-card border px-4 py-3 text-body",
        tone === "info" && "border-link/40 bg-link/10 text-text",
        tone === "warn" && "border-warn/40 bg-warn/10 text-text",
        tone === "error" && "border-error/40 bg-error/10 text-text",
        tone === "success" && "border-success/40 bg-success/10 text-text",
        className,
      )}
    >
      <Icon
        size={20}
        className={clsx(
          "mt-0.5 shrink-0",
          tone === "info" && "text-link",
          tone === "warn" && "text-warn",
          tone === "error" && "text-error",
          tone === "success" && "text-success",
        )}
      />
      <div className="flex-1">{children}</div>
      {actionLabel ? (
        <button
          type="button"
          onClick={onAction}
          className={clsx(
            "shrink-0 font-semibold underline-offset-2 hover:underline",
            TONE_ACTION[tone],
          )}
        >
          {actionLabel}
        </button>
      ) : null}
      {dismissable ? (
        <button
          type="button"
          aria-label="Dismiss"
          onClick={() => {
            setDismissed(true);
            onDismiss?.();
          }}
          className="shrink-0 text-text-2 hover:text-text"
        >
          <X size={16} />
        </button>
      ) : null}
    </div>
  );
}
