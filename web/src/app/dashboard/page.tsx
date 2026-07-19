// B1 — the feed at the dashboard base (web-implementation.md §4 route map).
import type { Metadata } from "next";
import { FeedView } from "@/components/dashboard/feed/FeedView";

export const metadata: Metadata = {
  title: "Home — Apparule",
};

export default function DashboardHomePage() {
  return <FeedView />;
}
