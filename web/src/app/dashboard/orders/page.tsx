// B3 — Requests & orders list (web-implementation.md §4 route map).
import type { Metadata } from "next";
import { OrdersView } from "@/components/dashboard/orders/OrdersView";

export const metadata: Metadata = {
  title: "Orders — Apparule",
};

export default function OrdersPage() {
  return <OrdersView />;
}
