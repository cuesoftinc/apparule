"use client";

// Notifications controller — activity list + unread badge (MI-16: badge
// clears on visit via markAllRead).
import { useCallback, useEffect, useMemo, useState } from "react";
import type { Notification } from "@/models";
import { notificationsRepo } from "@/models/repositories/notifications-repo";

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

  return { notifications, unreadCount, loading, error, reload, markAllRead };
}
