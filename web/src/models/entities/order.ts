// REQUEST (commission order) + satellites — data-model.md §5/§6.3/§6.5 and
// docs/order-lifecycle.md §1 (the state machine below is that contract).

export type OrderStatus =
  | "requested"
  | "quoted"
  | "paid"
  | "in_progress"
  | "shipped"
  | "delivered"
  | "refunded"
  | "declined"
  | "disputed"
  | "cancelled";

export const ORDER_STATUSES: readonly OrderStatus[] = [
  "requested",
  "quoted",
  "paid",
  "in_progress",
  "shipped",
  "delivered",
  "refunded",
  "declined",
  "disputed",
  "cancelled",
] as const;

/**
 * Allowed transitions per order-lifecycle.md §1. Terminal states have no
 * outgoing edges (delivered/refunded/declined/cancelled).
 */
export const ORDER_TRANSITIONS: Readonly<
  Record<OrderStatus, readonly OrderStatus[]>
> = {
  requested: ["quoted", "declined", "cancelled"],
  quoted: ["paid", "cancelled"],
  paid: ["in_progress", "refunded", "disputed"],
  in_progress: ["shipped", "disputed"],
  shipped: ["delivered", "disputed"],
  disputed: ["delivered", "refunded"],
  delivered: [],
  refunded: [],
  declined: [],
  cancelled: [],
};

export function canTransition(from: OrderStatus, to: OrderStatus): boolean {
  return ORDER_TRANSITIONS[from].includes(to);
}

/** Frozen at submit — later edits never mutate an order (data-model §6.3). */
export interface DeliveryAddress {
  recipient_name: string;
  phone: string;
  line1: string;
  line2?: string;
  city: string;
  state: string;
  country: string;
}

/** Frozen copy of vault values + method + measured_at (data-model §5). */
export interface MeasurementSnapshot {
  id: string;
  request_id: string;
  values: {
    method: string;
    measured_at: string;
    measurements: { name: string; value_cm: number }[];
  };
  created_at: string;
}

export interface OrderEvent {
  id: string;
  request_id: string;
  /** State transitions + reminders. */
  kind: string;
  actor: "customer" | "designer" | "system" | "moderator";
  created_at: string;
}

export interface ThreadMessage {
  id: string;
  request_id: string;
  author_id: string;
  /** ≤ 1000 chars; images only as attachments (order-lifecycle §5). */
  body: string;
  image_url: string | null;
  created_at: string;
}

export interface Payment {
  id: string;
  request_id: string;
  provider: "paystack" | "stripe";
  /** charge.success lands directly in held (Paystack capture model). */
  state: "held" | "released" | "refunded";
  currency: string;
  amount_cents: number;
  /** 10% of quote (A-1, ratified). */
  platform_fee_cents: number;
}

export type DeclineReason =
  | "workload"
  | "out_of_specialty"
  | "budget_too_low"
  | "timeline_too_tight"
  | "other";

export type DisputeReason =
  "not_received" | "not_as_described" | "size_wrong" | "other";

export interface CommissionRequest {
  id: string;
  /** Human display number, e.g. "APR-1042". */
  order_number: string;
  post: {
    id: string;
    caption: string;
    thumb_url: string;
  };
  customer: { id: string; username: string; avatar_url: string | null };
  designer: { id: string; username: string; avatar_url: string | null };
  status: OrderStatus;
  notes: string;
  budget_cents: number | null;
  quote_cents: number | null;
  /** ISO 4217; NGN-only v1 (A-1). */
  currency: string;
  due_at: string | null;
  target_date: string | null;
  tracking: string | null;
  decline_reason: DeclineReason | null;
  dispute: { reason: DisputeReason; detail: string | null } | null;
  delivery: DeliveryAddress;
  snapshot: MeasurementSnapshot;
  events: OrderEvent[];
  payment: Payment | null;
  created_at: string;
}
