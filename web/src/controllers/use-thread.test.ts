// Thread controller — MI-17/MI-18: optimistic send, failed-state rollback,
// typing pulse holding back the scripted counterparty reply.
import { beforeEach, describe, expect, it, vi } from "vitest";
import { act, renderHook, waitFor } from "@testing-library/react";

const messages = vi.fn();
const sendMessage = vi.fn();
vi.mock("@/models/repositories/orders-repo", () => ({
  ordersRepo: {
    messages: (...a: unknown[]) => messages(...a),
    sendMessage: (...a: unknown[]) => sendMessage(...a),
  },
}));

import { useThread } from "./use-thread";

const msg = (id: string, author: string, at = Date.now()) => ({
  id,
  request_id: "req-1",
  author_id: author,
  body: `body-${id}`,
  image_url: null,
  created_at: new Date(at).toISOString(),
});

beforeEach(() => {
  messages.mockReset();
  sendMessage.mockReset();
});

describe("useThread", () => {
  it("loads history and appends optimistic sends", async () => {
    const history = msg("m1", "des-a", Date.now() - 60_000);
    messages.mockResolvedValue({ items: [history], next_cursor: null });
    sendMessage.mockImplementation(async (_id: string, body: string) => {
      const sent = { ...msg("m2", "acc-kiki"), body };
      messages.mockResolvedValue({
        items: [history, sent],
        next_cursor: null,
      });
      return sent;
    });
    const { result } = renderHook(() => useThread("req-1", "acc-kiki"));
    await waitFor(() => expect(result.current.loading).toBe(false));
    await act(() => result.current.send("hello"));
    expect(result.current.messages.map((m) => m.id)).toContain("m2");
    expect(result.current.typing).toBe(false);
  });

  it("holds the scripted reply behind the typing pulse (MI-17)", async () => {
    vi.useFakeTimers();
    try {
      messages.mockResolvedValue({ items: [], next_cursor: null });
      const sentAt = Date.now();
      sendMessage.mockImplementation(async () => {
        const sent = msg("m-sent", "acc-kiki", sentAt);
        messages.mockResolvedValue({
          items: [sent, msg("m-reply", "des-a", sentAt + 1)],
          next_cursor: null,
        });
        return sent;
      });
      const { result } = renderHook(() => useThread("req-1", "acc-kiki"));
      await act(async () => {
        await vi.runOnlyPendingTimersAsync();
      });
      await act(async () => {
        const sendPromise = result.current.send("hi");
        await vi.waitFor(() => expect(sendMessage).toHaveBeenCalled());
        await sendPromise;
      });
      expect(result.current.typing).toBe(true);
      expect(result.current.messages.map((m) => m.id)).not.toContain("m-reply");
      await act(async () => {
        await vi.advanceTimersByTimeAsync(1700);
      });
      expect(result.current.typing).toBe(false);
      expect(result.current.messages.map((m) => m.id)).toContain("m-reply");
    } finally {
      vi.useRealTimers();
    }
  });

  it("marks failed sends and retries them (MI-18)", async () => {
    messages.mockResolvedValue({ items: [], next_cursor: null });
    sendMessage.mockRejectedValueOnce(new Error("boom"));
    const { result } = renderHook(() => useThread("req-1", "acc-kiki"));
    await waitFor(() => expect(result.current.loading).toBe(false));
    await act(() => result.current.send("will fail"));
    const failed = result.current.messages.find((m) => m.state === "failed");
    expect(failed).toBeTruthy();
    sendMessage.mockImplementation(async (_id: string, body: string) => {
      const sent = { ...msg("m-ok", "acc-kiki"), body };
      messages.mockResolvedValue({ items: [sent], next_cursor: null });
      return sent;
    });
    await act(() => result.current.retry(failed!));
    expect(result.current.messages.some((m) => m.state === "failed")).toBe(false);
    expect(result.current.messages.map((m) => m.id)).toContain("m-ok");
  });
});
