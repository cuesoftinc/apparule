// B9 — Earnings & payouts (web-implementation.md §4 route map).
import type { Metadata } from "next";
import { EarningsView } from "@/components/dashboard/earnings/EarningsView";

export const metadata: Metadata = {
  title: "Earnings — Apparule",
};

export default function EarningsPage() {
  return <EarningsView />;
}
