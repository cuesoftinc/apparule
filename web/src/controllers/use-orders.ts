"use client";

// Orders controller — B3 list + detail state, role tabs, lifecycle actions
// (order-lifecycle.md §2 permissions matrix drives which action fires).
import { useCallback, useEffect, useState } from "react";
import type { CommissionRequest, DeclineReason, DisputeReason } from "@/models";
import { ordersRepo } from "@/models/repositories/orders-repo";

export type OrdersRole = "customer" | "designer";

export function useOrders(role: OrdersRole) {
  const [orders, setOrders] = useState<CommissionRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Effect-safe fetch (react-hooks/set-state-in-effect): setState only in
  // promise callbacks; reload() re-arms loading from event handlers.
  const load = useCallback(
    () =>
      ordersRepo.list(role).then(
        (page) => {
          setOrders(page.items);
          setError(null);
          setLoading(false);
        },
        (e: unknown) => {
          setError(e instanceof Error ? e.message : "Failed to load orders");
          setLoading(false);
        },
      ),
    [role],
  );

  useEffect(() => {
    void load();
  }, [load]);

  const reload = useCallback(() => {
    setLoading(true);
    setError(null);
    return load();
  }, [load]);

  return { orders, loading, error, reload };
}

export function useOrder(id: string) {
  const [order, setOrder] = useState<CommissionRequest | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(
    () =>
      ordersRepo.get(id).then(
        (fetched) => {
          setOrder(fetched);
          setError(null);
          setLoading(false);
        },
        (e: unknown) => {
          setError(e instanceof Error ? e.message : "Failed to load order");
          setLoading(false);
        },
      ),
    [id],
  );

  useEffect(() => {
    void load();
  }, [load]);

  const reload = useCallback(() => {
    setLoading(true);
    setError(null);
    return load();
  }, [load]);

  const run = useCallback(
    async (action: () => Promise<CommissionRequest>) => {
      const updated = await action();
      setOrder(updated);
      return updated;
    },
    [],
  );

  return {
    order,
    loading,
    error,
    reload,
    quote: (quoteCents: number, dueAt: string) =>
      run(() => ordersRepo.quote(id, quoteCents, dueAt)),
    decline: (reason: DeclineReason, note?: string) =>
      run(() => ordersRepo.decline(id, reason, note)),
    setStatus: (status: "in_progress" | "shipped", tracking?: string) =>
      run(() => ordersRepo.setStatus(id, status, tracking)),
    pay: (idempotencyKey: string) => run(() => ordersRepo.pay(id, idempotencyKey)),
    cancel: () => run(() => ordersRepo.cancel(id)),
    confirmDelivery: () => run(() => ordersRepo.confirmDelivery(id)),
    dispute: (reason: DisputeReason, detail?: string) =>
      run(() => ordersRepo.dispute(id, reason, detail)),
  };
}
