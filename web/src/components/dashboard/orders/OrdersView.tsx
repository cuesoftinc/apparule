"use client";

// B3 — Requests & orders list: As customer / As designer tabs (designer tab
// only when the creator profile is enabled), RequestCard rows with status
// pills (MI-14) and per-state next actions; skeleton/empty states.
import { useState } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/auth/AuthContext";
import { useOrders, type OrdersRole } from "@/controllers/use-orders";
import { EmptyState } from "@/components/ui/EmptyState";
import { RequestCard } from "@/components/ui/RequestCard";
import { Skeleton } from "@/components/ui/Skeleton";
import { Tabs } from "@/components/ui/Tabs";

export function OrdersView() {
  const { account } = useAuth();
  const router = useRouter();
  const designerEnabled = account?.designer.enabled ?? false;
  const [tab, setTab] = useState<"first" | "second">("first");
  const role: OrdersRole =
    designerEnabled && tab === "second" ? "designer" : "customer";
  const { orders, loading, error, reload } = useOrders(role);

  return (
    <div className="mx-auto flex max-w-2xl flex-col gap-4 px-4 py-6">
      {/* Figma 179:364 carries no visible page title — tabs/list lead. */}
      <header>
        <h1 className="sr-only">Orders</h1>
      </header>

      {designerEnabled ? (
        <Tabs
          labels={["As customer", "As designer"]}
          active={tab}
          onChange={setTab}
        />
      ) : null}

      {loading ? (
        <div aria-busy="true" className="flex flex-col gap-3">
          <Skeleton kind="card" />
          <Skeleton kind="card" />
        </div>
      ) : error ? (
        <EmptyState
          context="orders"
          line="Orders couldn't load — try again."
          ctaLabel="Retry"
          onCta={() => void reload()}
        />
      ) : orders.length === 0 ? (
        <EmptyState
          context="orders"
          line={
            role === "designer"
              ? "No requests yet — publish outfits to get commissioned."
              : "Commission an outfit and it will show up here."
          }
          ctaLabel={role === "designer" ? "Create a post" : "Explore outfits"}
          onCta={() =>
            router.push(
              role === "designer" ? "/dashboard/create" : "/dashboard/explore",
            )
          }
        />
      ) : (
        <ul className="flex flex-col gap-3" data-testid="orders-list">
          {orders.map((order) => (
            <li key={order.id}>
              <RequestCard
                order={order}
                role={role}
                onOpen={() => router.push(`/dashboard/orders/${order.id}`)}
                onAction={() => router.push(`/dashboard/orders/${order.id}`)}
              />
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
