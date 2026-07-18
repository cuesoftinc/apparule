"use client";

// Toast — design.md §3/§8.2: icon + text, bottom, auto-dismiss 3s ·
// variants success / error+retry / neutral. Optimistic-action failures
// re-toast with Retry (MI-18). Entrance/exit use entrance/exit tokens.
import { useEffect } from "react";
import clsx from "clsx";
import { Check, X } from "lucide-react";

export type ToastKind = "success" | "error" | "neutral";

export interface ToastProps {
  kind?: ToastKind;
  message: string;
  /** error toasts render a Retry action when provided (MI-18 rollback). */
  onRetry?: () => void;
  onDismiss?: () => void;
  /** Auto-dismiss delay; 0 disables (design default 3s). */
  autoDismissMs?: number;
  className?: string;
}

// Figma master (41:2207): success = check, error = x, neutral = no icon.
const ICONS: Record<Exclude<ToastKind, "neutral">, typeof Check> = {
  success: Check,
  error: X,
};

export function Toast({
  kind = "neutral",
  message,
  onRetry,
  onDismiss,
  autoDismissMs = 3000,
  className,
}: ToastProps) {
  useEffect(() => {
    if (!onDismiss || autoDismissMs <= 0) return;
    const t = setTimeout(onDismiss, autoDismissMs);
    return () => clearTimeout(t);
  }, [onDismiss, autoDismissMs]);

  const Icon = kind === "neutral" ? null : ICONS[kind];
  return (
    <div
      role="status"
      aria-live="polite"
      data-kind={kind}
      className={clsx(
        "z-50 flex items-center gap-3 rounded-card bg-text px-4 py-3 text-body text-bg shadow-[0_4px_8px_rgba(0,0,0,0.25)]",
        "animate-[toast-in_250ms_var(--ap-ease-standard)] motion-reduce:animate-none",
        className,
      )}
    >
      {Icon ? (
        <Icon
          size={18}
          className={kind === "success" ? "text-success" : "text-error"}
        />
      ) : null}
      <span className="flex-1">{message}</span>
      {kind === "error" && onRetry ? (
        <button
          type="button"
          onClick={onRetry}
          className="font-semibold text-accent-start underline-offset-2 hover:underline"
        >
          Retry
        </button>
      ) : null}
    </div>
  );
}
