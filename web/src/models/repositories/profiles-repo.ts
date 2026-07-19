// Public profiles + social lists repository (pages.md B6; B2 designers
// section). api.md §5 carries no profile-read group yet — these mirror the
// mock's ahead-of-contract surface (stage-report deviation).
import { apiFetch, type Page } from "@/lib/api";
import type { Post } from "../entities/post";
import type { PublicProfile, UserSummary } from "../entities/profile";

export const profilesRepo = {
  /** GET /api/v1/profiles/{username} — designer or regular-user profile. */
  get: (username: string) =>
    apiFetch<PublicProfile>(`/v1/profiles/${username}`),

  /** GET /api/v1/profiles/{username}/posts — the B6 grid. */
  posts: (username: string, cursor?: string) =>
    apiFetch<Page<Post>>(
      `/v1/profiles/${username}/posts${cursor ? `?cursor=${cursor}` : ""}`,
    ),

  /** GET /api/v1/profiles/{username}/followers — UserRow sheet (MI-7). */
  followers: (username: string) =>
    apiFetch<Page<UserSummary>>(`/v1/profiles/${username}/followers`),

  /** GET /api/v1/profiles/{username}/following */
  following: (username: string) =>
    apiFetch<Page<UserSummary>>(`/v1/profiles/${username}/following`),

  /** GET /api/v1/me/saved — the viewer's saved looks (B6 saved tab). */
  saved: (cursor?: string) =>
    apiFetch<Page<Post>>(`/v1/me/saved${cursor ? `?cursor=${cursor}` : ""}`),
};
