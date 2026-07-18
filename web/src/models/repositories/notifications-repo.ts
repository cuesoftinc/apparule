// Notifications repository — api.md §5 (GET /notifications, POST /notifications/read).
import { apiFetch, type Page } from "@/lib/api";
import type { Notification } from "../entities/notification";

export const notificationsRepo = {
  /** GET /api/v1/notifications — activity list (90d retention). */
  list: (cursor?: string) =>
    apiFetch<Page<Notification>>(
      `/v1/notifications${cursor ? `?cursor=${cursor}` : ""}`,
    ),

  /** POST /api/v1/notifications/read — clears badges (MI-16). */
  markRead: (ids?: string[]) =>
    apiFetch<void>("/v1/notifications/read", {
      method: "POST",
      json: ids ? { ids } : {},
    }),
};
