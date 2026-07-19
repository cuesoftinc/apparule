// B3 — Order detail (web-implementation.md §4 route map).
import type { Metadata } from "next";
import { OrderDetailView } from "@/components/dashboard/orders/OrderDetailView";

export const metadata: Metadata = {
  title: "Order — Apparule",
};

export default async function OrderDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  return <OrderDetailView orderId={id} />;
}
