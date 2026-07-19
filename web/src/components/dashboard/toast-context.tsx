"use client";

// Dashboard toast host — view-layer surface for the MI-18 contract:
// optimistic-action failures re-toast with Retry; success/neutral toasts
// auto-dismiss (design.md §3 Toast). Pure UI state, so it lives with the
// views, not the controllers.
import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import { Toast, type ToastKind } from "@/components/ui/Toast";

export interface ToastInput {
  kind?: ToastKind;
  message: string;
  onRetry?: () => void;
}

interface ToastEntry extends ToastInput {
  id: number;
}

interface ToastContextValue {
  showToast: (input: ToastInput) => void;
}

const ToastContext = createContext<ToastContextValue | null>(null);

let toastSeq = 0;

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<ToastEntry[]>([]);

  const dismiss = useCallback((id: number) => {
    setToasts((prev) => prev.filter((t) => t.id !== id));
  }, []);

  const showToast = useCallback((input: ToastInput) => {
    const id = ++toastSeq;
    setToasts((prev) => [...prev.slice(-2), { ...input, id }]);
  }, []);

  const value = useMemo(() => ({ showToast }), [showToast]);

  return (
    <ToastContext.Provider value={value}>
      {children}
      {toasts.length > 0 ? (
        <div
          aria-live="polite"
          className="fixed inset-x-0 bottom-6 z-50 flex flex-col items-center gap-2 px-4"
        >
          {toasts.map((t) => (
            <Toast
              key={t.id}
              kind={t.kind}
              message={t.message}
              onRetry={
                t.onRetry
                  ? () => {
                      dismiss(t.id);
                      t.onRetry?.();
                    }
                  : undefined
              }
              onDismiss={() => dismiss(t.id)}
            />
          ))}
        </div>
      ) : null}
    </ToastContext.Provider>
  );
}

export function useToasts(): ToastContextValue {
  const ctx = useContext(ToastContext);
  if (!ctx) throw new Error("useToasts must be used within <ToastProvider>");
  return ctx;
}
