// Posts + engagement + social graph repository — api.md §5.
// Likes/saves/follows are idempotent PUT-style toggles with optimistic-client
// semantics (MI-18) — controllers flip UI state first, then call these.
import { env } from "@/config/env";
import { ApiError, apiFetch, type Page } from "@/lib/api";
import type { Comment, Post } from "../entities/post";
import { pollUntil, uploadWithTicket, type UploadTicket } from "./upload";

interface MediaBatch {
  id: string;
  status: "awaiting_upload" | "ready";
  items: { id: string; url: string; width: number; height: number }[];
  upload?: UploadTicket;
}

export interface PostCreate {
  caption: string;
  style_tags: string[];
  base_price_cents: number | null;
  turnaround_days: number;
  /** `media_id` names an uploaded image on the real backend (§6.1). */
  media: { url: string; alt_text: string; media_id?: string }[];
}

export const postsRepo = {
  /** GET /api/v1/posts/{id} — public permalink /p/{id}. */
  get: (id: string) => apiFetch<Post>(`/v1/posts/${id}`),

  /**
   * Composer image upload. TEST_MODE: POST /media (the mock's object-storage
   * stand-in). Real backend: reserve a media batch (ticket) → upload to
   * api/uploads → poll until stored; `url` is a short-lived preview.
   */
  uploadMedia: async (image: File): Promise<{ id: string; url: string }> => {
    if (!env.testMode) {
      const batch = await apiFetch<MediaBatch>("/v1/media/tickets", {
        method: "POST",
        json: { count: 1 },
      });
      await uploadWithTicket(batch.upload!, [["images", image]]);
      const ready = await pollUntil(
        () => apiFetch<MediaBatch>(`/v1/media/batches/${batch.id}`),
        (b) => b.status === "ready",
        { intervalMs: 1000, timeoutMs: 60_000 },
      );
      const item = ready.items[0];
      if (!item)
        throw new ApiError("upload_failed", "The image didn't upload", 503);
      return { id: item.id, url: item.url };
    }
    const form = new FormData();
    form.set("image", image);
    return apiFetch<{ id: string; url: string }>("/v1/media", {
      method: "POST",
      body: form,
    });
  },

  /** POST /api/v1/posts (designer, KYC-gated). */
  create: (input: PostCreate) =>
    apiFetch<Post>("/v1/posts", { method: "POST", json: input }),

  /** DELETE /api/v1/posts/{id} */
  remove: (id: string) =>
    apiFetch<void>(`/v1/posts/${id}`, { method: "DELETE" }),

  /** POST/DELETE /api/v1/posts/{id}/like */
  like: (id: string) =>
    apiFetch<void>(`/v1/posts/${id}/like`, { method: "POST" }),
  unlike: (id: string) =>
    apiFetch<void>(`/v1/posts/${id}/like`, { method: "DELETE" }),

  /** POST/DELETE /api/v1/posts/{id}/save */
  save: (id: string) =>
    apiFetch<void>(`/v1/posts/${id}/save`, { method: "POST" }),
  unsave: (id: string) =>
    apiFetch<void>(`/v1/posts/${id}/save`, { method: "DELETE" }),

  /** GET/POST /api/v1/posts/{id}/comments (body ≤500 chars). */
  comments: (id: string, cursor?: string) =>
    apiFetch<Page<Comment>>(
      `/v1/posts/${id}/comments${cursor ? `?cursor=${cursor}` : ""}`,
    ),
  addComment: (id: string, body: string) =>
    apiFetch<Comment>(`/v1/posts/${id}/comments`, {
      method: "POST",
      json: { body },
    }),

  /** POST/DELETE /api/v1/follows/{designer} */
  follow: (designerUsername: string) =>
    apiFetch<void>(`/v1/follows/${designerUsername}`, { method: "POST" }),
  unfollow: (designerUsername: string) =>
    apiFetch<void>(`/v1/follows/${designerUsername}`, { method: "DELETE" }),
};
