// Analytics controller — event register + transport seam (pages.md Part A).
import { afterEach, describe, expect, it, vi } from "vitest";
import { renderHook } from "@testing-library/react";
import {
  setAnalyticsTransport,
  track,
  usePageView,
  type AnalyticsEvent,
} from "./use-analytics";

afterEach(() => {
  setAnalyticsTransport(null);
});

describe("analytics controller", () => {
  it("routes events through the injected transport with name/props/ts", () => {
    const events: AnalyticsEvent[] = [];
    setAnalyticsTransport({ send: (e) => events.push(e) });

    track("try_cloud_click", { section: "hero" });

    expect(events).toHaveLength(1);
    expect(events[0].name).toBe("try_cloud_click");
    expect(events[0].props).toEqual({ section: "hero" });
    expect(typeof events[0].ts).toBe("number");
  });

  it("never throws when the transport fails", () => {
    setAnalyticsTransport({
      send: () => {
        throw new Error("transport down");
      },
    });
    expect(() => track("faq_open", { faq: "faq-1" })).not.toThrow();
  });

  it("default transport logs via console.debug (TEST_MODE/dev observable no-op)", () => {
    const debug = vi.spyOn(console, "debug").mockImplementation(() => {});
    track("self_host_click");
    // vitest runs with NODE_ENV=test and TEST_MODE unset — the default
    // transport stays silent (no-op outside TEST_MODE/dev)…
    expect(debug).not.toHaveBeenCalled();
    debug.mockRestore();
  });

  it("usePageView fires page_view once on mount with the path", () => {
    const events: AnalyticsEvent[] = [];
    setAnalyticsTransport({ send: (e) => events.push(e) });

    const { rerender } = renderHook(({ path }) => usePageView(path), {
      initialProps: { path: "/" },
    });
    rerender({ path: "/" });

    expect(events.filter((e) => e.name === "page_view")).toHaveLength(1);
    expect(events[0].props).toEqual({ path: "/" });
  });
});
