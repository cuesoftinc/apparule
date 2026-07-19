"use client";

// B3 — Order detail: outfit summary · immutable measurement snapshot ·
// thread (MI-17) · timeline (MI-14) · payment box (MI-15) · per-state
// actions from the order-lifecycle.md §2 permissions matrix (designer:
// quote/decline/start/ship · customer: cancel/pay/confirm-delivery ·
// either: dispute). Render-only over useOrder + useThread.
import { useMemo, useState, type FormEvent } from "react";
import Image from "next/image";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Clock } from "lucide-react";
import type { CommissionRequest, OrderStatus } from "@/models";
import { formatCm } from "@/lib/format";
import { useAuth } from "@/controllers/auth/AuthContext";
import { useOrder } from "@/controllers/use-orders";
import { useThread } from "@/controllers/use-thread";
import { AppBar } from "@/components/ui/AppBar";
import { Button } from "@/components/ui/Button";
import { humanizeMeasureName } from "@/components/ui/ManualMeasureRow";
import { OrderTimelineRow } from "@/components/ui/OrderTimelineRow";
import { PaymentBox, type PaymentBoxState } from "@/components/ui/PaymentBox";
import { Skeleton } from "@/components/ui/Skeleton";
import { StatusPill } from "@/components/ui/StatusPill";
import { ThreadBubble } from "@/components/ui/ThreadBubble";
import { Input } from "@/components/ui/Input";
import {
  ConfirmSheet,
  DeclineSheet,
  DisputeSheet,
  QuoteSheet,
  ShipSheet,
  DECLINE_REASONS,
} from "./OrderActionSheets";
import { useToasts } from "../toast-context";

const STATUS_LABEL: Record<string, string> = {
  requested: "Requested",
  quoted: "Quoted",
  paid: "Paid — escrow held",
  in_progress: "In progress",
  shipped: "Shipped",
  delivered: "Delivered",
  refunded: "Refunded",
  declined: "Declined",
  disputed: "Disputed",
  cancelled: "Cancelled",
};

const HAPPY_PATH: OrderStatus[] = [
  "requested",
  "quoted",
  "paid",
  "in_progress",
  "shipped",
  "delivered",
];
const ERROR_KINDS = new Set(["declined", "disputed", "refunded", "cancelled"]);
const TERMINAL: OrderStatus[] = [
  "delivered",
  "refunded",
  "declined",
  "cancelled",
];

function paymentBoxState(order: CommissionRequest): PaymentBoxState | null {
  if (order.status === "quoted") return "quoted";
  if (order.status === "disputed") return "dispute-frozen";
  if (order.payment?.state === "refunded") return "refunded";
  if (order.payment?.state === "released") return "released";
  if (order.payment?.state === "held") return "escrow-held";
  return null;
}

export function OrderDetailView({ orderId }: { orderId: string }) {
  const { account } = useAuth();
  const router = useRouter();
  const { showToast } = useToasts();
  const detail = useOrder(orderId);
  const order = detail.order;

  const viewerIsCustomer =
    order !== null && account?.username === order.customer.username;
  const role: "customer" | "designer" = viewerIsCustomer
    ? "customer"
    : "designer";
  const viewerPartyId = order
    ? viewerIsCustomer
      ? order.customer.id
      : order.designer.id
    : null;

  const thread = useThread(orderId, viewerPartyId);
  const [draft, setDraft] = useState("");
  const [sheet, setSheet] = useState<
    | null
    | "quote"
    | "decline"
    | "dispute"
    | "ship"
    | "cancel"
    | "confirm-delivery"
  >(null);
  const [paying, setPaying] = useState(false);
  const [justPaid, setJustPaid] = useState(false);

  // MI-14 timeline: actual events (done/terminal-error), current pulse on
  // the latest, then the remaining happy-path steps as pending.
  const timeline = useMemo(() => {
    if (!order) return [];
    const rows = order.events.map((event, i) => ({
      key: event.id,
      label: STATUS_LABEL[event.kind] ?? event.kind,
      timestamp: event.created_at,
      dot:
        i === order.events.length - 1
          ? ERROR_KINDS.has(event.kind)
            ? ("terminal-error" as const)
            : TERMINAL.includes(order.status)
              ? ("done" as const)
              : ("current" as const)
          : ERROR_KINDS.has(event.kind)
            ? ("terminal-error" as const)
            : ("done" as const),
    }));
    const pathIndex = HAPPY_PATH.indexOf(order.status);
    const pending =
      pathIndex >= 0
        ? HAPPY_PATH.slice(pathIndex + 1).map((status) => ({
            key: `pending-${status}`,
            label: STATUS_LABEL[status],
            timestamp: undefined,
            dot: "pending" as const,
          }))
        : [];
    return [...rows, ...pending];
  }, [order]);

  if (detail.loading) {
    return (
      <div aria-busy="true" className="mx-auto max-w-2xl px-4 py-6">
        <Skeleton kind="card" />
      </div>
    );
  }
  if (detail.error || !order) {
    return (
      <div className="mx-auto max-w-2xl px-4 py-12 text-center">
        <p role="alert" className="text-body text-text-2">
          This order isn&apos;t available.
        </p>
        <Link href="/dashboard/orders" className="text-body text-link">
          Back to orders
        </Link>
      </div>
    );
  }

  const counterparty = viewerIsCustomer
    ? order.designer.username
    : order.customer.username;
  const payState: PaymentBoxState | null = paying
    ? "paying"
    : paymentBoxState(order);

  const run = (label: string, action: () => Promise<unknown>) =>
    action()
      .then(() => setSheet(null))
      .catch(() =>
        showToast({ kind: "error", message: `Couldn't ${label} — try again.` }),
      );

  const pay = async () => {
    setPaying(true);
    try {
      await detail.pay(crypto.randomUUID());
      setJustPaid(true); // MI-15: escrow explainer expands on first payment
    } catch {
      showToast({ kind: "error", message: "Payment failed — try again." });
    } finally {
      setPaying(false);
    }
  };

  const sendMessage = (e: FormEvent) => {
    e.preventDefault();
    const body = draft.trim();
    if (!body) return;
    setDraft("");
    void thread.send(body);
  };

  return (
    <div className="mx-auto flex max-w-2xl flex-col px-4 pb-10">
      <AppBar
        kind="sub"
        title={`Order #${order.order_number}`}
        onBack={() => router.push("/dashboard/orders")}
      />

      <div className="flex flex-col gap-6 pt-4">
        <header
          aria-label="Order summary"
          className="flex items-center gap-3 rounded-card border border-border p-3"
        >
          <div className="relative h-16 w-16 shrink-0 overflow-hidden rounded-card">
            <Image
              src={order.post.thumb_url}
              alt=""
              fill
              sizes="64px"
              className="object-cover"
            />
          </div>
          <div className="min-w-0 flex-1">
            <h1 className="truncate text-body font-semibold text-text">
              {order.post.caption}
            </h1>
            <p className="text-caption text-text-2">
              {viewerIsCustomer ? "Designer" : "Customer"}:{" "}
              <Link href={`/dashboard/${counterparty}`} className="text-link">
                {counterparty}
              </Link>
            </p>
            {order.due_at ? (
              <p className="flex items-center gap-1 text-caption text-text-2">
                <Clock size={12} aria-hidden /> Due{" "}
                {new Date(order.due_at).toLocaleDateString("en-NG", {
                  month: "short",
                  day: "numeric",
                })}
              </p>
            ) : null}
          </div>
          <StatusPill status={order.status} />
        </header>

        <section aria-labelledby="order-timeline-h">
          <h2
            id="order-timeline-h"
            className="pb-2 text-body font-semibold text-text-2"
          >
            Timeline
          </h2>
          <ol>
            {timeline.map((row, i) => (
              <li key={row.key}>
                <OrderTimelineRow
                  dot={row.dot}
                  connector={i < timeline.length - 1 ? "drawn" : "none"}
                  label={row.label}
                  timestamp={row.timestamp}
                />
              </li>
            ))}
          </ol>
        </section>

        {payState && order.quote_cents !== null ? (
          <section aria-label="Payment">
            <PaymentBox
              state={payState}
              role={role}
              quoteCents={order.quote_cents}
              currency={order.currency}
              showEscrowExplainer={justPaid && payState === "escrow-held"}
              onPay={viewerIsCustomer ? () => void pay() : undefined}
            />
          </section>
        ) : null}

        <section aria-labelledby="order-snapshot-h">
          <h2
            id="order-snapshot-h"
            className="pb-2 text-body font-semibold text-text-2"
          >
            Measurement snapshot
          </h2>
          <div className="rounded-card border border-border px-3 py-2">
            <dl>
              {order.snapshot.values.measurements.map((m) => (
                <div
                  key={m.name}
                  className="flex justify-between py-1 text-body"
                >
                  <dt className="text-text-2">{humanizeMeasureName(m.name)}</dt>
                  <dd className="tnum text-text">{formatCm(m.value_cm)}</dd>
                </div>
              ))}
            </dl>
            <p className="border-t border-border pt-2 text-micro text-text-2">
              Frozen at request — vault changes never alter this order.
            </p>
          </div>
        </section>

        {order.notes ? (
          <section aria-labelledby="order-notes-h">
            <h2
              id="order-notes-h"
              className="pb-1 text-body font-semibold text-text-2"
            >
              Notes
            </h2>
            <p className="text-body text-text">{order.notes}</p>
          </section>
        ) : null}

        {order.decline_reason ? (
          <p className="text-body text-text-2">
            Declined:{" "}
            {DECLINE_REASONS.find((r) => r.value === order.decline_reason)
              ?.label ?? order.decline_reason}
          </p>
        ) : null}
        {order.dispute ? (
          <p className="text-body text-text-2">
            Dispute open ({order.dispute.reason.replaceAll("_", " ")})
            {order.dispute.detail ? ` — ${order.dispute.detail}` : ""}. Support
            resolves disputes; the payout stays frozen meanwhile.
          </p>
        ) : null}
        {order.tracking ? (
          <p className="text-body text-text-2">
            Tracking: <span className="tnum text-text">{order.tracking}</span>
          </p>
        ) : null}

        <section aria-label="Order actions" className="flex flex-wrap gap-2">
          {viewerIsCustomer ? (
            <>
              {order.status === "requested" ? (
                <Button kind="quiet" onClick={() => setSheet("cancel")}>
                  Cancel request
                </Button>
              ) : null}
              {order.status === "quoted" ? (
                <Button kind="quiet" onClick={() => setSheet("cancel")}>
                  Reject quote
                </Button>
              ) : null}
              {order.status === "shipped" ? (
                <Button
                  kind="gradient-primary"
                  onClick={() => setSheet("confirm-delivery")}
                  data-testid="confirm-delivery"
                >
                  Confirm delivery
                </Button>
              ) : null}
              {["paid", "in_progress", "shipped"].includes(order.status) ? (
                <Button kind="quiet" onClick={() => setSheet("dispute")}>
                  Something wrong?
                </Button>
              ) : null}
            </>
          ) : (
            <>
              {order.status === "requested" ? (
                <>
                  <Button
                    kind="gradient-primary"
                    onClick={() => setSheet("quote")}
                    data-testid="send-quote"
                  >
                    Send quote
                  </Button>
                  <Button kind="quiet" onClick={() => setSheet("decline")}>
                    Decline
                  </Button>
                </>
              ) : null}
              {order.status === "quoted" ? (
                <Button kind="quiet" onClick={() => setSheet("quote")}>
                  Edit quote
                </Button>
              ) : null}
              {order.status === "paid" ? (
                <Button
                  kind="gradient-primary"
                  onClick={() =>
                    void run("start work", () => detail.setStatus("in_progress"))
                  }
                >
                  Start work
                </Button>
              ) : null}
              {order.status === "in_progress" ? (
                <Button
                  kind="gradient-primary"
                  onClick={() => setSheet("ship")}
                >
                  Mark shipped
                </Button>
              ) : null}
              {["paid", "in_progress", "shipped"].includes(order.status) ? (
                <Button kind="quiet" onClick={() => setSheet("dispute")}>
                  Open dispute
                </Button>
              ) : null}
            </>
          )}
        </section>

        <section aria-labelledby="order-thread-h" className="flex flex-col">
          <h2
            id="order-thread-h"
            className="pb-2 text-body font-semibold text-text-2"
          >
            Thread
          </h2>
          {thread.loading ? (
            <Skeleton kind="line" />
          ) : (
            <ul className="flex flex-col gap-2" data-testid="order-thread">
              {thread.messages.map((message) => (
                <li key={message.id}>
                  <ThreadBubble
                    side={message.author_id === viewerPartyId ? "sent" : "received"}
                    text={message.body}
                    content={message.image_url ? "image" : "text"}
                    imageUrl={message.image_url ?? undefined}
                    state={message.state === "sent" ? undefined : message.state}
                    onRetry={
                      message.state === "failed"
                        ? () => void thread.retry(message)
                        : undefined
                    }
                  />
                </li>
              ))}
              {thread.typing ? (
                <li data-testid="thread-typing">
                  <ThreadBubble side="received" content="typing" />
                </li>
              ) : null}
            </ul>
          )}
          <form className="flex items-center gap-2 pt-3" onSubmit={sendMessage}>
            <label htmlFor="thread-draft" className="sr-only">
              Message {counterparty}
            </label>
            <Input
              id="thread-draft"
              placeholder={`Message ${counterparty}…`}
              value={draft}
              onChange={(e) => setDraft(e.target.value)}
              maxLength={1000}
            />
            <Button kind="link" type="submit" disabled={draft.trim().length === 0}>
              Send
            </Button>
          </form>
        </section>
      </div>

      <QuoteSheet
        open={sheet === "quote"}
        onOpenChange={(open) => setSheet(open ? "quote" : null)}
        initialQuoteCents={order.quote_cents}
        onSubmit={({ quoteCents, dueAt }) =>
          run("send the quote", () => detail.quote(quoteCents, dueAt))
        }
      />
      <DeclineSheet
        open={sheet === "decline"}
        onOpenChange={(open) => setSheet(open ? "decline" : null)}
        onSubmit={({ reason, note }) =>
          run("decline", () => detail.decline(reason, note || undefined))
        }
      />
      <DisputeSheet
        open={sheet === "dispute"}
        onOpenChange={(open) => setSheet(open ? "dispute" : null)}
        onSubmit={({ reason, detail: text }) =>
          run("open the dispute", () =>
            detail.dispute(reason, text || undefined),
          )
        }
      />
      <ShipSheet
        open={sheet === "ship"}
        onOpenChange={(open) => setSheet(open ? "ship" : null)}
        onSubmit={({ tracking }) =>
          run("mark shipped", () =>
            detail.setStatus("shipped", tracking || undefined),
          )
        }
      />
      <ConfirmSheet
        open={sheet === "cancel"}
        onOpenChange={(open) => setSheet(open ? "cancel" : null)}
        title={order.status === "quoted" ? "Reject quote?" : "Cancel request?"}
        body={
          order.status === "quoted"
            ? "The order will be cancelled and the designer notified."
            : "The designer will be notified and your snapshot deleted after 30 days."
        }
        confirmLabel={order.status === "quoted" ? "Reject quote" : "Cancel request"}
        destructive
        onConfirm={() => run("cancel", () => detail.cancel())}
      />
      <ConfirmSheet
        open={sheet === "confirm-delivery"}
        onOpenChange={(open) => setSheet(open ? "confirm-delivery" : null)}
        title="Confirm delivery?"
        body={`This releases the payout to ${order.designer.username}. Only confirm once you have the order in hand.`}
        confirmLabel="Confirm delivery"
        onConfirm={() => run("confirm delivery", () => detail.confirmDelivery())}
      />
    </div>
  );
}
