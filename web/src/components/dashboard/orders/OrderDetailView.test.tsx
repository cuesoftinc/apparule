// B3 order detail — the per-state action matrix (order-lifecycle.md §2) and
// PaymentBox state mapping (MI-15) rendered per role.
import { beforeEach, describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import type { CommissionRequest, OrderStatus } from "@/models";
import { ToastProvider } from "../toast-context";

const useOrderMock = vi.fn();
const account = {
  username: "kiki.adeyemi",
  designer: { enabled: false, kyc_complete: false },
};
vi.mock("@/controllers/auth/AuthContext", () => ({
  useAuth: () => ({ status: "signed_in", account }),
}));
vi.mock("@/controllers/use-orders", () => ({
  useOrder: (...a: unknown[]) => useOrderMock(...a),
}));
vi.mock("@/controllers/use-thread", () => ({
  useThread: () => ({
    messages: [],
    loading: false,
    typing: false,
    send: vi.fn(),
    retry: vi.fn(),
  }),
}));
vi.mock("next/navigation", () => ({
  useRouter: () => ({ push: vi.fn(), back: vi.fn(), replace: vi.fn() }),
}));

import { OrderDetailView } from "./OrderDetailView";

function order(
  status: OrderStatus,
  overrides: Partial<CommissionRequest> = {},
): CommissionRequest {
  return {
    id: "req-1",
    order_number: "APR-1100",
    post: {
      id: "post-1",
      caption: "Ankara gown",
      thumb_url: "/demo/outfit-w00.jpg",
    },
    customer: { id: "acc-kiki", username: "kiki.adeyemi", avatar_url: null },
    designer: { id: "des-amara", username: "amara.designs", avatar_url: null },
    status,
    notes: "",
    budget_cents: null,
    quote_cents: 4_500_000,
    currency: "NGN",
    due_at: null,
    target_date: null,
    tracking: null,
    decline_reason: null,
    dispute: null,
    delivery: {
      recipient_name: "Kiki",
      phone: "+234",
      line1: "14 St",
      city: "Lagos",
      state: "Lagos",
      country: "NG",
    },
    snapshot: {
      id: "snap",
      request_id: "req-1",
      values: {
        method: "manual",
        measured_at: "2026-07-01",
        measurements: [{ name: "shoulder_width", value_cm: 42.5 }],
      },
      created_at: "2026-07-01",
    },
    events: [
      {
        id: "e1",
        request_id: "req-1",
        kind: "requested",
        actor: "customer",
        created_at: "2026-07-01",
      },
    ],
    payment: ["paid", "in_progress", "shipped", "disputed"].includes(status)
      ? {
          id: "pay",
          request_id: "req-1",
          provider: "paystack",
          state: "held",
          currency: "NGN",
          amount_cents: 4_500_000,
          platform_fee_cents: 450_000,
        }
      : status === "delivered"
        ? {
            id: "pay",
            request_id: "req-1",
            provider: "paystack",
            state: "released",
            currency: "NGN",
            amount_cents: 4_500_000,
            platform_fee_cents: 450_000,
          }
        : status === "refunded"
          ? {
              id: "pay",
              request_id: "req-1",
              provider: "paystack",
              state: "refunded",
              currency: "NGN",
              amount_cents: 4_500_000,
              platform_fee_cents: 450_000,
            }
          : null,
    created_at: "2026-07-01",
    ...overrides,
  };
}

function renderDetail(o: CommissionRequest, viewer: "customer" | "designer") {
  account.username = viewer === "customer" ? "kiki.adeyemi" : "amara.designs";
  useOrderMock.mockReturnValue({
    order: o,
    loading: false,
    error: null,
    reload: vi.fn(),
    quote: vi.fn(),
    decline: vi.fn(),
    setStatus: vi.fn(),
    pay: vi.fn(),
    cancel: vi.fn(),
    confirmDelivery: vi.fn(),
    dispute: vi.fn(),
  });
  return render(
    <ToastProvider>
      <OrderDetailView orderId="req-1" />
    </ToastProvider>,
  );
}

beforeEach(() => {
  useOrderMock.mockReset();
});

describe("OrderDetailView — customer action matrix", () => {
  it("requested → Cancel request", () => {
    renderDetail(order("requested", { quote_cents: null }), "customer");
    expect(
      screen.getByRole("button", { name: "Cancel request" }),
    ).toBeInTheDocument();
  });

  it("quoted → Pay CTA (PaymentBox) + Reject quote", () => {
    renderDetail(order("quoted"), "customer");
    expect(screen.getByRole("button", { name: /^Pay/ })).toBeInTheDocument();
    expect(
      screen.getByRole("button", { name: "Reject quote" }),
    ).toBeInTheDocument();
  });

  it("shipped → Confirm delivery + dispute entry", () => {
    renderDetail(order("shipped"), "customer");
    expect(screen.getByTestId("confirm-delivery")).toBeInTheDocument();
    expect(
      screen.getByRole("button", { name: "Something wrong?" }),
    ).toBeInTheDocument();
  });

  it("delivered → released payment, no actions", () => {
    renderDetail(order("delivered"), "customer");
    expect(screen.queryByTestId("confirm-delivery")).not.toBeInTheDocument();
    expect(
      screen.queryByRole("button", { name: "Something wrong?" }),
    ).not.toBeInTheDocument();
  });
});

describe("OrderDetailView — designer action matrix", () => {
  it("requested → Send quote / Decline", () => {
    renderDetail(order("requested", { quote_cents: null }), "designer");
    expect(screen.getByTestId("send-quote")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Decline" })).toBeInTheDocument();
  });

  it("paid → Start work; in_progress → Mark shipped", () => {
    renderDetail(order("paid"), "designer");
    expect(
      screen.getByRole("button", { name: "Start work" }),
    ).toBeInTheDocument();
    renderDetail(order("in_progress"), "designer");
    expect(
      screen.getByRole("button", { name: "Mark shipped" }),
    ).toBeInTheDocument();
  });

  it("disputed → payout frozen, no designer transitions", () => {
    renderDetail(
      order("disputed", { dispute: { reason: "size_wrong", detail: null } }),
      "designer",
    );
    expect(
      screen.queryByRole("button", { name: "Mark shipped" }),
    ).not.toBeInTheDocument();
    expect(
      screen.queryByRole("button", { name: "Start work" }),
    ).not.toBeInTheDocument();
    // dispute-frozen PaymentBox state renders
    expect(screen.getAllByText(/frozen/i).length).toBeGreaterThan(0);
  });
});

describe("OrderDetailView — snapshot immutability note", () => {
  it("renders the frozen snapshot with its rule line", () => {
    renderDetail(order("in_progress"), "customer");
    expect(screen.getByText("Shoulder Width")).toBeInTheDocument();
    expect(
      screen.getByText(/vault changes never alter this order/i),
    ).toBeInTheDocument();
  });
});
