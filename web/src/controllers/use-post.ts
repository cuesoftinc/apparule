"use client";

// Post-detail controller — powers the B2 post modal and the /p/{id}
// permalink: post + comments, optimistic like/save/comment (MI-18), report.
import { useCallback, useEffect, useState } from "react";
import type { Comment, Post, ReportReason } from "@/models";
import { moderationRepo } from "@/models/repositories/moderation-repo";
import { postsRepo } from "@/models/repositories/posts-repo";

export function usePost(id: string | null) {
  const [post, setPost] = useState<Post | null>(null);
  const [comments, setComments] = useState<Comment[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Consumers mount one instance per post id (modal keyed by id, permalink
  // route) — loading starts true and only promise callbacks set state
  // (react-hooks/set-state-in-effect).
  useEffect(() => {
    if (!id) return;
    let cancelled = false;
    Promise.all([postsRepo.get(id), postsRepo.comments(id)]).then(
      ([fetchedPost, commentPage]) => {
        if (cancelled) return;
        setPost(fetchedPost);
        setComments(commentPage.items);
        setLoading(false);
      },
      (e: unknown) => {
        if (cancelled) return;
        setError(e instanceof Error ? e.message : "Failed to load post");
        setLoading(false);
      },
    );
    return () => {
      cancelled = true;
    };
  }, [id]);

  /** Optimistic like (MI-1/2 + MI-18 rollback). */
  const toggleLike = useCallback(async () => {
    if (!post) return;
    const was = post;
    const liked = !was.liked;
    setPost({
      ...was,
      liked,
      like_count: was.like_count + (liked ? 1 : -1),
    });
    try {
      await (liked ? postsRepo.like(was.id) : postsRepo.unlike(was.id));
    } catch {
      setPost((p) =>
        p ? { ...p, liked: was.liked, like_count: was.like_count } : p,
      );
      throw new Error("like_failed");
    }
  }, [post]);

  /** Optimistic save (MI-3 + MI-18 rollback). */
  const toggleSave = useCallback(async () => {
    if (!post) return;
    const was = post;
    setPost({ ...was, saved: !was.saved });
    try {
      await (was.saved ? postsRepo.unsave(was.id) : postsRepo.save(was.id));
    } catch {
      setPost((p) => (p ? { ...p, saved: was.saved } : p));
      throw new Error("save_failed");
    }
  }, [post]);

  /** Optimistic comment post (MI-18) — replaced by the server row. */
  const addComment = useCallback(
    async (body: string) => {
      if (!id) return;
      const optimistic: Comment = {
        id: `optimistic-${Date.now()}`,
        post_id: id,
        author: { id: "me", username: "you", avatar_url: null },
        body,
        like_count: 0,
        liked: false,
        hidden_by_moderation: false,
        created_at: new Date().toISOString(),
      };
      setComments((prev) => [...prev, optimistic]);
      setPost((p) => (p ? { ...p, comment_count: p.comment_count + 1 } : p));
      try {
        const saved = await postsRepo.addComment(id, body);
        setComments((prev) =>
          prev.map((c) => (c.id === optimistic.id ? saved : c)),
        );
      } catch {
        setComments((prev) => prev.filter((c) => c.id !== optimistic.id));
        setPost((p) => (p ? { ...p, comment_count: p.comment_count - 1 } : p));
        throw new Error("comment_failed");
      }
    },
    [id],
  );

  /** Report post (SOC-009) — PostCard ⋯ overflow. */
  const report = useCallback(
    async (reason: ReportReason, detail?: string) => {
      if (!id) return;
      await moderationRepo.fileReport("post", id, reason, detail);
    },
    [id],
  );

  return {
    post,
    comments,
    loading,
    error,
    toggleLike,
    toggleSave,
    addComment,
    report,
  };
}
