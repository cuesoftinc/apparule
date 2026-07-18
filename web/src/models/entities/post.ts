// POST / POST_MEDIA / COMMENT entities — data-model.md §5, §6.5.

export interface PostMedia {
  id: string;
  post_id: string;
  /** Web mock serves from /demo/… (public dir); production uses object storage URLs. */
  url: string;
  position: number;
  /** Required at publish; default "Outfit by {designer}" (design.md §5). */
  alt_text: string;
  width: number;
  height: number;
}

export interface PostDesigner {
  id: string;
  username: string;
  display_name: string;
  avatar_url: string | null;
  verified: boolean;
}

export interface Post {
  id: string;
  designer: PostDesigner;
  caption: string;
  style_tags: string[];
  /** null = "quote on request" */
  base_price_cents: number | null;
  currency: string;
  turnaround_days: number;
  media: PostMedia[];
  like_count: number;
  comment_count: number;
  /** Viewer state (optimistic toggles, MI-18). */
  liked: boolean;
  saved: boolean;
  created_at: string;
}

export interface Comment {
  id: string;
  post_id: string;
  author: {
    id: string;
    username: string;
    avatar_url: string | null;
  };
  /** ≤ 500 chars (api.md §5). */
  body: string;
  like_count: number;
  liked: boolean;
  hidden_by_moderation: boolean;
  created_at: string;
}
