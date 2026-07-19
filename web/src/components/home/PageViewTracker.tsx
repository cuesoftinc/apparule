"use client";

// Fires the pages.md Part A `page_view` event on mount (analytics
// controller; no-op/log transport until Upstat ingestion lands at D2).
import { usePageView } from "@/controllers/analytics";

export function PageViewTracker({ path }: { path: string }) {
  usePageView(path);
  return null;
}
