"use client";

// Order-thread controller (B3 detail, MI-17/MI-18): messages, optimistic
// send with rollback, and the counterparty "responding…" indicator — the
// mock scripts one auto-reply per thread; the controller holds it back
// behind a typing pulse before revealing it.
import { useCallback, useEffect, useRef, useState } from "react";
import type { ThreadMessage } from "@/models";
import { ordersRepo } from "@/models/repositories/orders-repo";

const TYPING_MS = 1600;

export interface OutgoingMessage extends ThreadMessage {
  state: "sending" | "sent" | "failed";
}

export function useThread(orderId: string, viewerPartyId: string | null) {
  const [messages, setMessages] = useState<OutgoingMessage[]>([]);
  const [loading, setLoading] = useState(true);
  const [typing, setTyping] = useState(false);
  const typingTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    let cancelled = false;
    ordersRepo.messages(orderId).then(
      (page) => {
        if (cancelled) return;
        setMessages(page.items.map((m) => ({ ...m, state: "sent" })));
        setLoading(false);
      },
      () => {
        if (!cancelled) setLoading(false);
      },
    );
    return () => {
      cancelled = true;
      if (typingTimer.current) clearTimeout(typingTimer.current);
    };
  }, [orderId]);

  const send = useCallback(
    async (body: string, imageUrl?: string) => {
      const optimistic: OutgoingMessage = {
        id: `optimistic-${Date.now()}`,
        request_id: orderId,
        author_id: viewerPartyId ?? "me",
        body,
        image_url: imageUrl ?? null,
        state: "sending",
        created_at: new Date().toISOString(),
      };
      setMessages((prev) => [...prev, optimistic]);
      try {
        const saved = await ordersRepo.sendMessage(orderId, body, imageUrl);
        setMessages((prev) =>
          prev.map((m) =>
            m.id === optimistic.id ? { ...saved, state: "sent" } : m,
          ),
        );
        // Counterparty replies land at/after the sent message's timestamp
        // (the mock's scripted auto-reply) — reveal after the MI-17 pulse.
        const page = await ordersRepo.messages(orderId);
        const sentAt = new Date(saved.created_at).getTime();
        const incoming = page.items.filter(
          (m) =>
            m.id !== saved.id &&
            m.author_id !== saved.author_id &&
            new Date(m.created_at).getTime() >= sentAt,
        );
        if (incoming.length > 0) {
          setTyping(true);
          typingTimer.current = setTimeout(() => {
            setTyping(false);
            setMessages((prev) => [
              ...prev,
              ...incoming
                .filter((m) => !prev.some((p) => p.id === m.id))
                .map((m) => ({ ...m, state: "sent" as const })),
            ]);
          }, TYPING_MS);
        }
      } catch {
        setMessages((prev) =>
          prev.map((m) =>
            m.id === optimistic.id ? { ...m, state: "failed" } : m,
          ),
        );
      }
    },
    [orderId, viewerPartyId],
  );

  const retry = useCallback(
    (failed: OutgoingMessage) => {
      setMessages((prev) => prev.filter((m) => m.id !== failed.id));
      return send(failed.body, failed.image_url ?? undefined);
    },
    [send],
  );

  return { messages, loading, typing, send, retry };
}
