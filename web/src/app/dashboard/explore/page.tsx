// B2 — Explore/Discover (web-implementation.md §4 route map).
import type { Metadata } from "next";
import { ExploreView } from "@/components/dashboard/explore/ExploreView";

export const metadata: Metadata = {
  title: "Explore — Apparule",
};

export default function ExplorePage() {
  return <ExploreView />;
}
