// Request-stepper controller — MI-10 / flows/request.md §1: picker preload,
// step gating, delivery prefill, idempotent submit, failure taxonomy.
import { beforeEach, describe, expect, it, vi } from "vitest";
import { act, renderHook, waitFor } from "@testing-library/react";
import type { Post } from "@/models";
import { ApiError } from "@/lib/api";

const sessions = vi.fn();
const listOrders = vi.fn();
const createRequest = vi.fn();
vi.mock("@/models/repositories/vault-repo", () => ({
  vaultRepo: { sessions: (...a: unknown[]) => sessions(...a) },
}));
vi.mock("@/models/repositories/orders-repo", () => ({
  ordersRepo: {
    list: (...a: unknown[]) => listOrders(...a),
    create: (...a: unknown[]) => createRequest(...a),
  },
}));

import { useRequestStepper } from "./use-request-stepper";

const post = {
  id: "post-1",
  base_price_cents: 4_500_000,
  turnaround_days: 14,
} as Post;

const session = (id: string, daysOld: number, status = "complete") => ({
  id,
  customer_id: "acc-kiki",
  method: "manual",
  input_height_cm: 168,
  status,
  measurements: [{ id: "m", session_id: id, name: "shoulder_width", value_cm: 42, source: "pipeline", confidence: null }],
  pipeline_meta: {},
  created_at: new Date(Date.now() - daysOld * 86_400_000).toISOString(),
});

const delivery = {
  recipient_name: "Kiki",
  phone: "+234",
  line1: "14 St",
  city: "Lagos",
  state: "Lagos",
  country: "NG",
};

beforeEach(() => {
  sessions.mockReset();
  listOrders.mockReset();
  createRequest.mockReset();
  sessions.mockResolvedValue({
    items: [session("s-new", 5), session("s-old", 120), session("s-pending", 1, "pending_save")],
    next_cursor: null,
  });
  listOrders.mockResolvedValue({
    items: [{ delivery }],
    next_cursor: null,
  });
});

describe("useRequestStepper", () => {
  it("preselects the first complete session and prefills delivery", async () => {
    const { result } = renderHook(() => useRequestStepper(post));
    await waitFor(() => expect(result.current.sessions.length).toBe(2)); // pending filtered
    expect(result.current.selectedSessionId).toBe("s-new");
    await waitFor(() =>
      expect(result.current.details.delivery.recipient_name).toBe("Kiki"),
    );
  });

  it("warns on stale (>90d) selections — warning, not block", async () => {
    const { result } = renderHook(() => useRequestStepper(post));
    await waitFor(() => expect(result.current.sessions.length).toBe(2));
    act(() => result.current.setSelectedSessionId("s-old"));
    expect(result.current.staleWarning).toBe(true);
    expect(result.current.canContinue).toBe(true);
  });

  it("gates step 2 on a complete delivery address", async () => {
    listOrders.mockResolvedValue({ items: [], next_cursor: null });
    const { result } = renderHook(() => useRequestStepper(post));
    await waitFor(() => expect(result.current.sessions.length).toBe(2));
    act(() => result.current.next());
    expect(result.current.step).toBe(1);
    expect(result.current.canContinue).toBe(false);
    act(() =>
      result.current.setDetails({
        ...result.current.details,
        delivery,
      }),
    );
    expect(result.current.canContinue).toBe(true);
  });

  it("submits with one idempotency key and surfaces the created order", async () => {
    createRequest.mockResolvedValue({ id: "req-1", order_number: "APR-1100" });
    const { result } = renderHook(() => useRequestStepper(post));
    await waitFor(() => expect(result.current.sessions.length).toBe(2));
    act(() =>
      result.current.setDetails({ ...result.current.details, delivery }),
    );
    await act(() => result.current.submit());
    expect(result.current.createdOrder?.id).toBe("req-1");
    const key = createRequest.mock.calls[0][2];
    expect(typeof key).toBe("string");
    expect((key as string).length).toBeGreaterThan(10);
  });

  it("maps the failure taxonomy (duplicate_request keeps the code)", async () => {
    createRequest.mockRejectedValue(
      new ApiError("duplicate_request", "You already have an open request", 409),
    );
    const { result } = renderHook(() => useRequestStepper(post));
    await waitFor(() => expect(result.current.sessions.length).toBe(2));
    act(() =>
      result.current.setDetails({ ...result.current.details, delivery }),
    );
    await act(() => result.current.submit());
    expect(result.current.failure?.code).toBe("duplicate_request");
    expect(result.current.createdOrder).toBeNull();
  });

  it("snapshot_invalid returns to step 1 with a refreshed picker", async () => {
    createRequest.mockRejectedValue(
      new ApiError("snapshot_invalid", "Session unusable", 422),
    );
    const { result } = renderHook(() => useRequestStepper(post));
    await waitFor(() => expect(result.current.sessions.length).toBe(2));
    act(() =>
      result.current.setDetails({ ...result.current.details, delivery }),
    );
    act(() => result.current.next());
    act(() => result.current.next());
    expect(result.current.step).toBe(2);
    await act(() => result.current.submit());
    expect(result.current.step).toBe(0);
    expect(result.current.failure?.code).toBe("snapshot_invalid");
  });
});
