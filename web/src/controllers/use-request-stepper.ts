"use client";

// Request-stepper controller (MI-10, flows/request.md §1): three steps —
// Measurements (vault snapshot picker) → Details (notes/budget/delivery/
// target date) → Review → submit with an Idempotency-Key per stepper
// session (exactly-one request under retry). Owns every stepper state; the
// sheet view renders from it.
import { useCallback, useEffect, useMemo, useState } from "react";
import type {
  CommissionRequest,
  DeliveryAddress,
  MeasurementSession,
  Post,
} from "@/models";
import { freshnessOf } from "@/models";
import { ApiError } from "@/lib/api";
import { ordersRepo } from "@/models/repositories/orders-repo";
import { vaultRepo } from "@/models/repositories/vault-repo";

export type StepperStep = 0 | 1 | 2;

export interface StepperDetails {
  notes: string;
  budgetCents: number | null;
  targetDate: string | null;
  delivery: Partial<DeliveryAddress>;
}

export interface StepperFailure {
  code: string;
  message: string;
}

const REQUIRED_DELIVERY: (keyof DeliveryAddress)[] = [
  "recipient_name",
  "phone",
  "line1",
  "city",
  "state",
  "country",
];

/** Soft warning: target date earlier than the designer's turnaround —
 * module fn keeps the clock read out of render scope. */
function isTurnaroundTight(
  post: Post | null,
  targetDate: string | null,
): boolean {
  if (!post || !targetDate) return false;
  const minimum = Date.now() + post.turnaround_days * 86_400_000;
  return new Date(targetDate).getTime() < minimum;
}

export function useRequestStepper(post: Post | null) {
  const [step, setStep] = useState<StepperStep>(0);
  const [sessions, setSessions] = useState<MeasurementSession[]>([]);
  const [sessionsLoaded, setSessionsLoaded] = useState(false);
  const [selectedSessionId, setSelectedSessionId] = useState<string | null>(
    null,
  );
  const [details, setDetails] = useState<StepperDetails>({
    notes: "",
    budgetCents: null,
    targetDate: null,
    delivery: {},
  });
  const [submitting, setSubmitting] = useState(false);
  const [failure, setFailure] = useState<StepperFailure | null>(null);
  const [createdOrder, setCreatedOrder] = useState<CommissionRequest | null>(
    null,
  );
  // One idempotency key per stepper session (flows/request.md submit rule).
  const [idempotencyKey, setIdempotencyKey] = useState(() =>
    crypto.randomUUID(),
  );

  const active = post !== null;

  // Loading is derived (react-hooks/set-state-in-effect): the sheet is open
  // while a post is set and data settles only in promise callbacks.
  const sessionsLoading = active && !sessionsLoaded;

  // Step 1 data: complete vault sessions, latest preselected; step 2
  // delivery pre-fills from the most recent order (pages.md C5 note).
  useEffect(() => {
    if (!active) return;
    let cancelled = false;
    vaultRepo.sessions().then(
      (page) => {
        if (cancelled) return;
        const complete = page.items.filter((s) => s.status === "complete");
        setSessions(complete);
        setSelectedSessionId((prev) => prev ?? complete[0]?.id ?? null);
        setSessionsLoaded(true);
      },
      () => {
        if (!cancelled) setSessionsLoaded(true);
      },
    );
    ordersRepo.list("customer").then(
      (page) => {
        if (cancelled) return;
        const last = page.items[0];
        if (last) {
          setDetails((d) =>
            Object.keys(d.delivery).length === 0
              ? { ...d, delivery: last.delivery }
              : d,
          );
        }
      },
      () => {
        // no previous orders — delivery stays blank
      },
    );
    return () => {
      cancelled = true;
    };
  }, [active]);

  const selectedSession = useMemo(
    () => sessions.find((s) => s.id === selectedSessionId) ?? null,
    [sessions, selectedSessionId],
  );

  /** Step-1 freshness warning (>90d — warn, never block). */
  const staleWarning =
    selectedSession !== null &&
    freshnessOf(selectedSession.created_at) === "stale";

  /** Soft warning: budget below the designer's base price. */
  const budgetWarning =
    post?.base_price_cents != null &&
    details.budgetCents !== null &&
    details.budgetCents < post.base_price_cents;

  const turnaroundWarning = useMemo(
    () => isTurnaroundTight(post, details.targetDate),
    [post, details.targetDate],
  );

  const deliveryComplete = REQUIRED_DELIVERY.every(
    (k) => (details.delivery[k] ?? "").toString().trim().length > 0,
  );

  const canContinue =
    step === 0
      ? selectedSession !== null
      : step === 1
        ? deliveryComplete
        : true;

  const next = useCallback(() => {
    setFailure(null);
    setStep((s) => (s < 2 ? ((s + 1) as StepperStep) : s));
  }, []);
  const back = useCallback(() => {
    setFailure(null);
    setStep((s) => (s > 0 ? ((s - 1) as StepperStep) : s));
  }, []);

  const reset = useCallback(() => {
    setStep(0);
    setFailure(null);
    setCreatedOrder(null);
    setSubmitting(false);
    setIdempotencyKey(crypto.randomUUID());
  }, []);

  const submit = useCallback(async () => {
    if (!post || !selectedSessionId || submitting) return;
    setSubmitting(true);
    setFailure(null);
    try {
      const order = await ordersRepo.create(
        post.id,
        {
          session_id: selectedSessionId,
          notes: details.notes || undefined,
          budget_cents: details.budgetCents ?? undefined,
          target_date: details.targetDate ?? undefined,
          delivery: details.delivery as DeliveryAddress,
        },
        idempotencyKey,
      );
      setCreatedOrder(order);
    } catch (e) {
      // Failure taxonomy per flows/request.md §1.
      if (e instanceof ApiError) {
        setFailure({ code: e.code, message: e.message });
        if (e.code === "snapshot_invalid") {
          // Session vanished between steps — back to the picker, refreshed.
          setStep(0);
          setSelectedSessionId(null);
          const page = await vaultRepo.sessions().catch(() => null);
          if (page) {
            const complete = page.items.filter((s) => s.status === "complete");
            setSessions(complete);
            setSelectedSessionId(complete[0]?.id ?? null);
          }
        }
      } else {
        setFailure({
          code: "network_failed",
          message: "Something went wrong — try again.",
        });
      }
    } finally {
      setSubmitting(false);
    }
  }, [post, selectedSessionId, details, idempotencyKey, submitting]);

  return {
    step,
    sessions,
    sessionsLoading,
    selectedSessionId,
    setSelectedSessionId,
    selectedSession,
    details,
    setDetails,
    staleWarning,
    budgetWarning,
    turnaroundWarning,
    deliveryComplete,
    canContinue,
    next,
    back,
    reset,
    submit,
    submitting,
    failure,
    createdOrder,
  };
}
