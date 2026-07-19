"use client";

// B3 order-detail secondary flows, each in a Sheet (design.md §3):
// quote (price + due date, due_at ≥ today+1) · decline-with-reason
// (enum + optional note, reason required — flows/designer.md §2) ·
// dispute (reason picker + note, order-lifecycle §1) · mark-shipped
// (tracking optional) · generic confirm (cancel / confirm-delivery).
import { useState } from "react";
import type { DeclineReason, DisputeReason } from "@/models";
import { Button } from "@/components/ui/Button";
import { DateInput, minDueDate } from "@/components/ui/DateInput";
import { FormRow } from "@/components/ui/FormRow";
import { Input } from "@/components/ui/Input";
import { Select } from "@/components/ui/Select";
import { Sheet } from "@/components/ui/Sheet";

interface ActionSheetProps<T> {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (value: T) => Promise<void>;
}

export const DECLINE_REASONS: { value: DeclineReason; label: string }[] = [
  { value: "workload", label: "Fully booked right now" },
  { value: "out_of_specialty", label: "Outside my specialty" },
  { value: "budget_too_low", label: "Budget too low" },
  { value: "timeline_too_tight", label: "Timeline too tight" },
  { value: "other", label: "Other" },
];

export const DISPUTE_REASONS: { value: DisputeReason; label: string }[] = [
  { value: "not_received", label: "Order not received" },
  { value: "not_as_described", label: "Not as described" },
  { value: "size_wrong", label: "Size is wrong" },
  { value: "other", label: "Other" },
];

export function QuoteSheet({
  open,
  onOpenChange,
  onSubmit,
  initialQuoteCents,
}: ActionSheetProps<{ quoteCents: number; dueAt: string }> & {
  initialQuoteCents?: number | null;
}) {
  const [amount, setAmount] = useState(
    initialQuoteCents ? String(initialQuoteCents / 100) : "",
  );
  const [dueAt, setDueAt] = useState<Date | null>(null);
  const [busy, setBusy] = useState(false);
  const parsed = Number(amount.replace(/[^\d.]/g, ""));
  const valid = Number.isFinite(parsed) && parsed > 0 && dueAt !== null;

  return (
    <Sheet open={open} onOpenChange={onOpenChange} title="Send a quote">
      <form
        className="flex flex-col gap-4"
        onSubmit={(e) => {
          e.preventDefault();
          if (!valid || !dueAt) return;
          setBusy(true);
          onSubmit({
            quoteCents: Math.round(parsed * 100),
            dueAt: dueAt.toISOString().slice(0, 10),
          }).finally(() => setBusy(false));
        }}
      >
        <FormRow label="Quote" required>
          <Input
            kind="currency"
            aria-label="Quote amount"
            placeholder="45,000"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
          />
        </FormRow>
        <FormRow label="Due date" helper="At least tomorrow" required>
          <DateInput
            aria-label="Due date"
            value={dueAt}
            onChange={setDueAt}
            minDate={minDueDate()}
          />
        </FormRow>
        <footer className="flex justify-end">
          <Button kind="gradient-primary" type="submit" disabled={!valid} loading={busy}>
            Send quote
          </Button>
        </footer>
      </form>
    </Sheet>
  );
}

export function DeclineSheet({
  open,
  onOpenChange,
  onSubmit,
}: ActionSheetProps<{ reason: DeclineReason; note: string }>) {
  const [reason, setReason] = useState<DeclineReason | undefined>();
  const [note, setNote] = useState("");
  const [busy, setBusy] = useState(false);

  return (
    <Sheet open={open} onOpenChange={onOpenChange} title="Decline request">
      <form
        className="flex flex-col gap-4"
        onSubmit={(e) => {
          e.preventDefault();
          if (!reason) return;
          setBusy(true);
          onSubmit({ reason, note }).finally(() => setBusy(false));
        }}
      >
        <Select
          aria-label="Decline reason"
          placeholder="Why are you declining?"
          options={DECLINE_REASONS}
          value={reason}
          onValueChange={(v) => setReason(v as DeclineReason)}
        />
        <Input
          kind="textarea"
          aria-label="Note to the customer"
          placeholder="Optional note for the customer"
          maxLength={500}
          value={note}
          onChange={(e) => setNote(e.target.value)}
        />
        <footer className="flex justify-end">
          <Button kind="destructive" type="submit" disabled={!reason} loading={busy}>
            Decline
          </Button>
        </footer>
      </form>
    </Sheet>
  );
}

export function DisputeSheet({
  open,
  onOpenChange,
  onSubmit,
}: ActionSheetProps<{ reason: DisputeReason; detail: string }>) {
  const [reason, setReason] = useState<DisputeReason | undefined>();
  const [detail, setDetail] = useState("");
  const [busy, setBusy] = useState(false);

  return (
    <Sheet open={open} onOpenChange={onOpenChange} title="Open a dispute">
      <form
        className="flex flex-col gap-4"
        onSubmit={(e) => {
          e.preventDefault();
          if (!reason) return;
          setBusy(true);
          onSubmit({ reason, detail }).finally(() => setBusy(false));
        }}
      >
        <p className="text-body text-text-2">
          Disputes freeze the payout while support reviews the order.
        </p>
        <Select
          aria-label="Dispute reason"
          placeholder="What went wrong?"
          options={DISPUTE_REASONS}
          value={reason}
          onValueChange={(v) => setReason(v as DisputeReason)}
        />
        <Input
          kind="textarea"
          aria-label="Dispute details"
          placeholder="Tell support what happened"
          maxLength={500}
          value={detail}
          onChange={(e) => setDetail(e.target.value)}
        />
        <footer className="flex justify-end">
          <Button kind="destructive" type="submit" disabled={!reason} loading={busy}>
            Open dispute
          </Button>
        </footer>
      </form>
    </Sheet>
  );
}

export function ShipSheet({
  open,
  onOpenChange,
  onSubmit,
}: ActionSheetProps<{ tracking: string }>) {
  const [tracking, setTracking] = useState("");
  const [busy, setBusy] = useState(false);

  return (
    <Sheet open={open} onOpenChange={onOpenChange} title="Mark shipped">
      <form
        className="flex flex-col gap-4"
        onSubmit={(e) => {
          e.preventDefault();
          setBusy(true);
          onSubmit({ tracking: tracking.trim() }).finally(() => setBusy(false));
        }}
      >
        <FormRow label="Tracking number" helper="Optional">
          <Input
            aria-label="Tracking number"
            placeholder="GIG-0000-LAG"
            value={tracking}
            onChange={(e) => setTracking(e.target.value)}
          />
        </FormRow>
        <footer className="flex justify-end">
          <Button kind="gradient-primary" type="submit" loading={busy}>
            Mark shipped
          </Button>
        </footer>
      </form>
    </Sheet>
  );
}

export function ConfirmSheet({
  open,
  onOpenChange,
  title,
  body,
  confirmLabel,
  destructive = false,
  onConfirm,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  title: string;
  body: string;
  confirmLabel: string;
  destructive?: boolean;
  onConfirm: () => Promise<void>;
}) {
  const [busy, setBusy] = useState(false);
  return (
    <Sheet open={open} onOpenChange={onOpenChange} title={title}>
      <div className="flex flex-col gap-4">
        <p className="text-body text-text-2">{body}</p>
        <footer className="flex justify-end gap-2">
          <Button kind="quiet" onClick={() => onOpenChange(false)}>
            Cancel
          </Button>
          <Button
            kind={destructive ? "destructive" : "gradient-primary"}
            loading={busy}
            onClick={() => {
              setBusy(true);
              onConfirm().finally(() => setBusy(false));
            }}
          >
            {confirmLabel}
          </Button>
        </footer>
      </div>
    </Sheet>
  );
}
