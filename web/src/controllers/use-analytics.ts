"use client";

// Analytics controller — the pages.md Part A event register (page_view,
// demo_start, github_click, try_cloud_click, self_host_click) plus the W2
// iteration events (contribute_click, faq_open). Events fire through a
// transport interface; Upstat ingestion (D2) lands behind it later —
// today's default transport no-ops in production and logs in TEST_MODE /
// development so journeys are observable without a backend.
import { useEffect } from "react";
import { env } from "@/config/env";

export type AnalyticsEventName =
  | "page_view"
  | "demo_start"
  | "github_click"
  | "try_cloud_click"
  | "self_host_click"
  | "contribute_click"
  | "faq_open";

export interface AnalyticsEvent {
  name: AnalyticsEventName;
  props?: Record<string, string | number | boolean>;
  /** Epoch ms, stamped at track() time. */
  ts: number;
}

/** Transport seam — Upstat ingestion implements this at D2. */
export interface AnalyticsTransport {
  send(event: AnalyticsEvent): void;
}

/** Default transport: log in TEST_MODE/dev, no-op otherwise. */
const consoleTransport: AnalyticsTransport = {
  send(event) {
    if (env.testMode || process.env.NODE_ENV === "development") {
      console.debug("[analytics]", event.name, event.props ?? {});
    }
  },
};

let transport: AnalyticsTransport = consoleTransport;

/** Swap the transport (Upstat later; tests inject a spy). */
export function setAnalyticsTransport(next: AnalyticsTransport | null): void {
  transport = next ?? consoleTransport;
}

/** Fire an event through the active transport (never throws). */
export function track(
  name: AnalyticsEventName,
  props?: Record<string, string | number | boolean>,
): void {
  try {
    transport.send({ name, props, ts: Date.now() });
  } catch {
    // analytics must never break the product surface
  }
}

/** page_view on mount (per path — re-fires on client-side navigation). */
export function usePageView(path: string): void {
  useEffect(() => {
    track("page_view", { path });
  }, [path]);
}
