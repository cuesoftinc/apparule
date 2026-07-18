"use client";

// Toast — design.md §3/§8.2: icon + text, bottom, auto-dismiss 3s ·
// variants success / error+retry / neutral. Optimistic-action failures
// re-toast with Retry (MI-18). Entrance/exit use entrance/exit tokens.
import { useEffect } from "react";
import clsx from "clsx";
import { AlertCircle, CheckCircle2, Info } from "lucide-react";

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

const ICONS: Record<ToastKind, typeof Info> = {
  success: CheckCircle2,
  error: AlertCircle,
  neutral: Info,
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

  const Icon = ICONS[kind];
  return (
    <div
      role="status"
      aria-live="polite"
      data-kind={kind}
      className={clsx(
        "z-50 flex items-center gap-3 rounded-card bg-text px-4 py-3 text-body text-bg shadow-lg",
        "animate-[toast-in_250ms_var(--ap-ease-standard)] motion-reduce:animate-none",
        className,
      )}
    >
      <Icon
        size={20}
        className={clsx(
          kind === "success" && "text-success",
          kind === "error" && "text-error",
          kind === "neutral" && "text-bg",
        )}
      />
      <span className="flex-1">{message}</span>
      {kind === "error" && onRetry ? (
        <button
          type="button"
          onClick={onRetry}
          className="font-semibold text-bg underline-offset-2 hover:underline"
        >
          Retry
        </button>
      ) : null}
    </div>
  );
}
