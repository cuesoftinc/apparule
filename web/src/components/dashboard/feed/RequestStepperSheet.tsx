"use client";

// Request stepper (MI-10, flows/request.md §1): 3-step sheet — Measurements
// (snapshot picker + freshness warning) → Details (notes/budget/delivery/
// target date with soft warnings) → Review (snapshot expandable + legal
// line) → submit (Idempotency-Key) → confetti ≤800ms + "View order".
// Render-only: all state lives in useRequestStepper.
import { useId, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { ChevronDown } from "lucide-react";
import type { Post } from "@/models";
import { formatNaira, formatCm } from "@/lib/format";
import {
  useRequestStepper,
  type StepperDetails,
} from "@/controllers/use-request-stepper";
import { humanizeMeasureName } from "@/components/ui/ManualMeasureRow";
import { AddressFieldset } from "@/components/ui/AddressFieldset";
import { Banner } from "@/components/ui/Banner";
import { Button } from "@/components/ui/Button";
import { DateInput } from "@/components/ui/DateInput";
import { EmptyState } from "@/components/ui/EmptyState";
import { FormRow } from "@/components/ui/FormRow";
import { Input } from "@/components/ui/Input";
import { SessionRow } from "@/components/ui/SessionRow";
import { Sheet } from "@/components/ui/Sheet";
import { Skeleton } from "@/components/ui/Skeleton";

const STEPS = ["Measurements", "Notes & budget", "Review"];

export interface RequestStepperSheetProps {
  post: Post | null;
  onOpenChange: (open: boolean) => void;
}

/** MI-10 success confetti — 12 accent dots, ≤800ms, reduced-motion safe. */
function ConfettiBurst() {
  return (
    <div
      aria-hidden
      data-testid="confetti"
      className="pointer-events-none absolute inset-0 overflow-hidden motion-reduce:hidden"
    >
      {Array.from({ length: 12 }, (_, i) => (
        <span
          key={i}
          className="absolute left-1/2 top-1/3 h-2 w-2 rounded-full"
          style={{
            background: i % 2 === 0 ? "var(--ap-accent-start)" : "var(--ap-accent-end)",
            animation: `ap-confetti 0.8s var(--ap-ease-exit) forwards`,
            transform: `rotate(${i * 30}deg)`,
          }}
        />
      ))}
      <style>{`@keyframes ap-confetti { to { translate: 0 -96px; opacity: 0; scale: 0.4; } }`}</style>
    </div>
  );
}

export function RequestStepperSheet({
  post,
  onOpenChange,
}: RequestStepperSheetProps) {
  const stepper = useRequestStepper(post);
  const budgetId = useId();
  const [snapshotOpen, setSnapshotOpen] = useState(false);

  const close = (open: boolean) => {
    onOpenChange(open);
    if (!open) stepper.reset();
  };

  if (!post) return null;

  const {
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
    canContinue,
    next,
    back,
    submit,
    submitting,
    failure,
    createdOrder,
  } = stepper;

  const setDetail = <K extends keyof StepperDetails>(
    key: K,
    value: StepperDetails[K],
  ) => setDetails({ ...details, [key]: value });

  return (
    <Sheet
      open={post !== null}
      onOpenChange={close}
      title="Request this outfit"
      stepper={createdOrder ? undefined : { steps: STEPS, current: step }}
    >
      {createdOrder ? (
        <section
          aria-label="Request submitted"
          className="relative flex flex-col items-center gap-4 py-8 text-center"
        >
          <ConfettiBurst />
          <span
            aria-hidden
            className="flex h-14 w-14 items-center justify-center rounded-full bg-accent-gradient text-title text-on-accent"
          >
            ✓
          </span>
          <h3 className="text-title font-bold text-text">Request sent</h3>
          <p className="max-w-sm text-body text-text-2">
            {createdOrder.designer.username} has your measurements for order #
            {createdOrder.order_number} — you&apos;ll hear back with a quote.
          </p>
          <Link
            href={`/dashboard/orders/${createdOrder.id}`}
            className="inline-flex h-11 items-center justify-center rounded-card bg-accent-gradient px-4 text-body font-semibold text-on-accent"
          >
            View order
          </Link>
        </section>
      ) : (
        <div className="flex flex-col gap-4">
          {failure ? (
            <Banner
              tone="error"
              actionLabel={
                failure.code === "duplicate_request" ? "View orders" : undefined
              }
              onAction={
                failure.code === "duplicate_request"
                  ? () => {
                      window.location.assign("/dashboard/orders");
                    }
                  : undefined
              }
            >
              {failure.message}
            </Banner>
          ) : null}

          {step === 0 ? (
            <fieldset className="flex flex-col gap-2" data-testid="stepper-step-1">
              <legend className="pb-2 text-body text-text-2">
                Pick the measurement set to share — only {post.designer.username}{" "}
                sees it, only for this order.
              </legend>
              {sessionsLoading ? (
                <Skeleton kind="card" />
              ) : sessions.length === 0 ? (
                <EmptyState
                  context="vault"
                  line="You need measurements first — capture or enter them in your vault."
                  ctaLabel="Go to vault"
                  onCta={() => window.location.assign("/dashboard/vault")}
                />
              ) : (
                <ul className="flex flex-col gap-2">
                  {sessions.map((session) => (
                    <li key={session.id}>
                      <SessionRow
                        session={session}
                        context="picker"
                        selected={session.id === selectedSessionId}
                        onSelect={() => setSelectedSessionId(session.id)}
                      />
                    </li>
                  ))}
                </ul>
              )}
              {staleWarning ? (
                <Banner tone="warn">
                  These measurements are more than 90 days old — consider a
                  retake before commissioning.
                </Banner>
              ) : null}
            </fieldset>
          ) : null}

          {step === 1 ? (
            <div className="flex flex-col gap-4" data-testid="stepper-step-2">
              <FormRow label="Notes for the designer">
                <Input
                  kind="textarea"
                  aria-label="Notes for the designer"
                  placeholder="Fit preferences, occasion, fabric ideas…"
                  maxLength={500}
                  value={details.notes}
                  onChange={(e) => setDetail("notes", e.target.value)}
                />
              </FormRow>
              <FormRow
                label="Budget (optional)"
                helper={
                  post.base_price_cents !== null
                    ? `Designer's base price is ${formatNaira(post.base_price_cents)}`
                    : undefined
                }
              >
                <Input
                  id={budgetId}
                  kind="currency"
                  aria-label="Budget"
                  placeholder="45,000"
                  value={
                    details.budgetCents !== null
                      ? String(details.budgetCents / 100)
                      : ""
                  }
                  onChange={(e) => {
                    const parsed = Number(e.target.value.replace(/[^\d.]/g, ""));
                    setDetail(
                      "budgetCents",
                      Number.isFinite(parsed) && e.target.value !== ""
                        ? Math.round(parsed * 100)
                        : null,
                    );
                  }}
                />
              </FormRow>
              {budgetWarning ? (
                <Banner tone="warn">
                  Your budget is below the designer&apos;s base price — they may
                  decline or quote higher.
                </Banner>
              ) : null}
              <FormRow label="Target date (optional)">
                <DateInput
                  aria-label="Target date"
                  value={details.targetDate ? new Date(details.targetDate) : null}
                  onChange={(date) =>
                    setDetail(
                      "targetDate",
                      date ? date.toISOString().slice(0, 10) : null,
                    )
                  }
                  minDate={new Date()}
                />
              </FormRow>
              {turnaroundWarning ? (
                <Banner tone="warn">
                  Designer&apos;s typical turnaround is {post.turnaround_days}{" "}
                  days — that date may be tight.
                </Banner>
              ) : null}
              <AddressFieldset
                context="delivery"
                value={details.delivery}
                onChange={(delivery) => setDetail("delivery", delivery)}
              />
            </div>
          ) : null}

          {step === 2 ? (
            <div className="flex flex-col gap-4" data-testid="stepper-step-3">
              <section
                aria-label="Outfit summary"
                className="flex items-center gap-3 rounded-card border border-border p-3"
              >
                <div className="relative h-14 w-14 shrink-0 overflow-hidden rounded-card">
                  <Image
                    src={post.media[0]?.url ?? ""}
                    alt={post.media[0]?.alt_text ?? ""}
                    fill
                    sizes="56px"
                    className="object-cover"
                  />
                </div>
                <div className="min-w-0">
                  <p className="truncate text-body font-semibold text-text">
                    {post.caption.split(" — ")[0]}
                  </p>
                  <p className="text-caption text-text-2">
                    {post.designer.username}
                    {post.base_price_cents !== null
                      ? ` · from ${formatNaira(post.base_price_cents)}`
                      : " · quote on request"}
                  </p>
                </div>
              </section>

              {selectedSession ? (
                <section
                  aria-label="Measurement snapshot"
                  className="rounded-card border border-border"
                >
                  <button
                    type="button"
                    className="flex w-full items-center justify-between px-3 py-2 text-body font-semibold text-text"
                    aria-expanded={snapshotOpen}
                    onClick={() => setSnapshotOpen((v) => !v)}
                  >
                    Snapshot · {selectedSession.measurements.length} values
                    <ChevronDown
                      size={20}
                      className={
                        snapshotOpen
                          ? "rotate-180 transition-transform duration-200 ease-standard motion-reduce:transition-none"
                          : "transition-transform duration-200 ease-standard motion-reduce:transition-none"
                      }
                    />
                  </button>
                  {snapshotOpen ? (
                    <ul className="border-t border-border px-3 py-2">
                      {selectedSession.measurements.map((m) => (
                        <li
                          key={m.id}
                          className="flex justify-between py-1 text-body"
                        >
                          <span className="text-text-2">
                            {humanizeMeasureName(m.name)}
                          </span>
                          <span className="tnum text-text">
                            {formatCm(m.value_cm)}
                          </span>
                        </li>
                      ))}
                    </ul>
                  ) : null}
                </section>
              ) : null}

              <dl className="flex flex-col gap-1 text-body">
                {details.notes ? (
                  <div className="flex justify-between gap-4">
                    <dt className="shrink-0 text-text-2">Notes</dt>
                    <dd className="text-right text-text">{details.notes}</dd>
                  </div>
                ) : null}
                <div className="flex justify-between gap-4">
                  <dt className="text-text-2">Budget</dt>
                  <dd className="tnum text-text">
                    {details.budgetCents !== null
                      ? formatNaira(details.budgetCents)
                      : "Open to quote"}
                  </dd>
                </div>
                <div className="flex justify-between gap-4">
                  <dt className="text-text-2">Deliver to</dt>
                  <dd className="text-right text-text">
                    {details.delivery.recipient_name}, {details.delivery.city}
                  </dd>
                </div>
              </dl>

              <p className="text-micro text-text-2">
                Measurements are AI-assisted estimates — confirm critical fits.
                Your measurements are shared only with this designer, for this
                order.
              </p>
            </div>
          ) : null}

          <footer className="flex items-center justify-between gap-2 pt-2">
            {step > 0 ? (
              <Button kind="quiet" onClick={back}>
                Back
              </Button>
            ) : (
              <span />
            )}
            {step < 2 ? (
              <Button
                kind="gradient-primary"
                disabled={!canContinue}
                onClick={next}
              >
                Continue
              </Button>
            ) : (
              <Button
                kind="gradient-primary"
                loading={submitting}
                onClick={() => void submit()}
                data-testid="stepper-submit"
              >
                Submit request
              </Button>
            )}
          </footer>
        </div>
      )}
    </Sheet>
  );
}
