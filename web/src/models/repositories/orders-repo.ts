// Commission requests/orders repository — api.md §5 (Requests + Payments
// groups); transitions enforced per order-lifecycle.md §1–2.
import { env } from "@/config/env";
import { ApiError, apiFetch, type Page } from "@/lib/api";
import { type Checkout, openCheckout } from "@/lib/paystack";
import type {
  CommissionRequest,
  DeclineReason,
  DeliveryAddress,
  DisputeReason,
  ThreadMessage,
} from "../entities/order";
import { pollUntil } from "./upload";

/** POST /pay on the real backend: the order (still quoted) + its checkout. */
type PayStarted = CommissionRequest & { checkout?: Checkout };

/**
 * Real backend (§6.3): open Paystack's checkout, then wait for the webhook
 * to settle the charge — the order turns paid server-side only.
 */
async function payOnBackend(
  id: string,
  idempotencyKey: string,
): Promise<CommissionRequest> {
  const started = await apiFetch<PayStarted>(`/v1/requests/${id}/pay`, {
    method: "POST",
    headers: { "Idempotency-Key": idempotencyKey },
  });
  if (!started.checkout) return started;
  const result = await openCheckout(started.checkout);
  if (result === "cancelled") {
    throw new ApiError("payment_cancelled", "Payment was cancelled", 409);
  }
  const order = await pollUntil(
    () => apiFetch<CommissionRequest>(`/v1/requests/${id}`),
    (o) => o.status !== "quoted",
    { intervalMs: 2000, timeoutMs: 90_000 },
  );
  if (order.status === "quoted") {
    throw new ApiError(
      "payment_pending",
      "Payment received — confirming it can take a minute",
      202,
    );
  }
  return order;
}

export interface RequestCreate {
  session_id: string;
  notes?: string;
  budget_cents?: number;
  currency?: string;
  target_date?: string;
  delivery: DeliveryAddress;
}

export const ordersRepo = {
  /** POST /api/v1/posts/{id}/requests — snapshot frozen server-side. */
  create: (postId: string, input: RequestCreate, idempotencyKey: string) =>
    apiFetch<CommissionRequest>(`/v1/posts/${postId}/requests`, {
      method: "POST",
      json: input,
      headers: { "Idempotency-Key": idempotencyKey },
    }),

  /** GET /api/v1/requests?role=customer|designer */
  list: (role: "customer" | "designer", cursor?: string) =>
    apiFetch<Page<CommissionRequest>>(
      `/v1/requests?role=${role}${cursor ? `&cursor=${cursor}` : ""}`,
    ),

  /** GET /api/v1/requests/{id} — party-only; others get 404. */
  get: (id: string) => apiFetch<CommissionRequest>(`/v1/requests/${id}`),

  /** POST /api/v1/requests/{id}/quote — designer (7d expiry). */
  quote: (id: string, quoteCents: number, dueAt: string) =>
    apiFetch<CommissionRequest>(`/v1/requests/${id}/quote`, {
      method: "POST",
      json: { quote_cents: quoteCents, currency: "NGN", due_at: dueAt },
    }),

  /** POST /api/v1/requests/{id}/decline — reason required (flows/designer §2). */
  decline: (id: string, reason: DeclineReason, note?: string) =>
    apiFetch<CommissionRequest>(`/v1/requests/${id}/decline`, {
      method: "POST",
      json: { reason, note },
    }),

  /** POST /api/v1/requests/{id}/status — designer: in_progress | shipped only. */
  setStatus: (
    id: string,
    status: "in_progress" | "shipped",
    tracking?: string,
  ) =>
    apiFetch<CommissionRequest>(`/v1/requests/${id}/status`, {
      method: "POST",
      json: { status, tracking },
    }),

  /** POST /api/v1/requests/{id}/cancel — customer withdraws / rejects the
   * quote (order-lifecycle.md §1; endpoint is mock-ahead-of-contract). */
  cancel: (id: string) =>
    apiFetch<CommissionRequest>(`/v1/requests/${id}/cancel`, {
      method: "POST",
    }),

  /**
   * POST /api/v1/requests/{id}/pay — escrow hold (MI-15). TEST_MODE: the
   * mock holds at once. Real backend: Paystack checkout, then the webhook.
   */
  pay: (id: string, idempotencyKey: string) =>
    env.testMode
      ? apiFetch<CommissionRequest>(`/v1/requests/${id}/pay`, {
          method: "POST",
          headers: { "Idempotency-Key": idempotencyKey },
        })
      : payOnBackend(id, idempotencyKey),

  /** POST /api/v1/requests/{id}/confirm-delivery — releases payout (−10% fee). */
  confirmDelivery: (id: string) =>
    apiFetch<CommissionRequest>(`/v1/requests/${id}/confirm-delivery`, {
      method: "POST",
    }),

  /** POST /api/v1/requests/{id}/dispute — freezes payout. */
  dispute: (id: string, reason: DisputeReason, detail?: string) =>
    apiFetch<CommissionRequest>(`/v1/requests/${id}/dispute`, {
      method: "POST",
      json: { reason, detail },
    }),

  /** GET/POST /api/v1/requests/{id}/messages (≤1000 chars, optional image). */
  messages: (id: string, cursor?: string) =>
    apiFetch<Page<ThreadMessage>>(
      `/v1/requests/${id}/messages${cursor ? `?cursor=${cursor}` : ""}`,
    ),
  sendMessage: (id: string, body: string, imageUrl?: string) =>
    apiFetch<ThreadMessage>(`/v1/requests/${id}/messages`, {
      method: "POST",
      json: { body, image_url: imageUrl ?? null },
    }),
};
