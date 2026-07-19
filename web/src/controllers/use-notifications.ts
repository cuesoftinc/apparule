"use client";

// Notifications controller — activity list + unread badge (MI-16: badge
// clears on visit via markAllRead).
import { useCallback, useEffect, useMemo, useState } from "react";
import type { Notification, NotificationKind } from "@/models";
import { notificationsRepo } from "@/models/repositories/notifications-repo";

/** Kinds that light the Orders rail badge (MI-16). */
export const ORDER_NOTIFICATION_KINDS: readonly NotificationKind[] = [
  "quote",
  "status_change",
  "payout",
];

export function useNotifications() {
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Effect-safe fetch (react-hooks/set-state-in-effect): setState only in
  // promise callbacks; reload() re-arms loading from event handlers.
  const load = useCallback(
    () =>
      notificationsRepo.list().then(
        (page) => {
          setNotifications(page.items);
          setError(null);
          setLoading(false);
        },
        (e: unknown) => {
          setError(
            e instanceof Error ? e.message : "Failed to load notifications",
          );
          setLoading(false);
        },
      ),
    [],
  );

  useEffect(() => {
    void load();
  }, [load]);

  const reload = useCallback(() => {
    setLoading(true);
    setError(null);
    return load();
  }, [load]);

  const unreadCount = useMemo(
    () => notifications.filter((n) => n.read_at === null).length,
    [notifications],
  );

  /** Unread order-kind count — the Orders rail badge (MI-16). */
  const ordersBadge = useMemo(
    () =>
      notifications.filter(
        (n) => n.read_at === null && ORDER_NOTIFICATION_KINDS.includes(n.kind),
      ).length,
    [notifications],
  );

  /** MI-16: the badge clears on tab visit — order kinds only. */
  const markOrderKindsRead = useCallback(async () => {
    const ids = notifications
      .filter(
        (n) => n.read_at === null && ORDER_NOTIFICATION_KINDS.includes(n.kind),
      )
      .map((n) => n.id);
    if (ids.length === 0) return;
    const now = new Date().toISOString();
    setNotifications((prev) =>
      prev.map((n) => (ids.includes(n.id) ? { ...n, read_at: now } : n)),
    );
    try {
      await notificationsRepo.markRead(ids);
    } catch {
      // non-fatal: badge re-derives on next load
    }
  }, [notifications]);

  const markAllRead = useCallback(async () => {
    const now = new Date().toISOString();
    setNotifications((prev) =>
      prev.map((n) => (n.read_at === null ? { ...n, read_at: now } : n)),
    );
    try {
      await notificationsRepo.markRead();
    } catch {
      // non-fatal: badge re-derives on next load
    }
  }, []);

  return {
    notifications,
    unreadCount,
    ordersBadge,
    loading,
    error,
    reload,
    markAllRead,
    markOrderKindsRead,
  };
}
