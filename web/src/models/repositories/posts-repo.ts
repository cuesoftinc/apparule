// Posts + engagement + social graph repository — api.md §5.
// Likes/saves/follows are idempotent PUT-style toggles with optimistic-client
// semantics (MI-18) — controllers flip UI state first, then call these.
import { apiFetch, type Page } from "@/lib/api";
import type { Comment, Post } from "../entities/post";

export interface PostCreate {
  caption: string;
  style_tags: string[];
  base_price_cents: number | null;
  turnaround_days: number;
  media: { url: string; alt_text: string }[];
}

export const postsRepo = {
  /** GET /api/v1/posts/{id} — public permalink /p/{id}. */
  get: (id: string) => apiFetch<Post>(`/v1/posts/${id}`),

  /** POST /api/v1/media — composer image upload (object-storage stand-in). */
  uploadMedia: (image: File) => {
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
