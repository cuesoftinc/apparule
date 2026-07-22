"use client";

// Post detail (B2 modal body + /p/{id} permalink): IG desktop pattern —
// media left, detail right (header · caption · comments · action row ·
// composer · request CTA). Render-only over usePost.
import { useState, type FormEvent } from "react";
import Image from "next/image";
import Link from "next/link";
import { ChevronLeft, ChevronRight, MoreHorizontal } from "lucide-react";
import type { Post } from "@/models";
import { formatAgo, formatNaira } from "@/lib/format";
import { usePost } from "@/controllers/use-post";
import { useAuth } from "@/auth/AuthContext";
import { ActionRow } from "@/components/ui/ActionRow";
import { Avatar } from "@/components/ui/Avatar";
import { Button } from "@/components/ui/Button";
import { CommentRow } from "@/components/ui/CommentRow";
import { IconButton } from "@/components/ui/IconButton";
import { Input } from "@/components/ui/Input";
import { Skeleton } from "@/components/ui/Skeleton";
import { maybeFirstSaveToast } from "../first-save";
import { useToasts } from "../toast-context";

export interface PostDetailViewProps {
  postId: string;
  onRequest?: (post: Post) => void;
  onOverflow?: (post: Post) => void;
}

export function PostDetailView({
  postId,
  onRequest,
  onOverflow,
}: PostDetailViewProps) {
  const { post, comments, loading, error, toggleLike, toggleSave, addComment } =
    usePost(postId);
  const { account } = useAuth();
  const { showToast } = useToasts();
  const [slide, setSlide] = useState(0);
  const [draft, setDraft] = useState("");
  const [posting, setPosting] = useState(false);

  if (loading) {
    return (
      <div aria-busy="true" className="grid gap-4 md:grid-cols-2">
        <Skeleton kind="media" />
        <Skeleton kind="card" />
      </div>
    );
  }
  if (error || !post) {
    return (
      <p role="alert" className="py-12 text-center text-body text-text-2">
        This post isn&apos;t available anymore.
      </p>
    );
  }

  const media = post.media[Math.min(slide, post.media.length - 1)];

  const submitComment = async (e: FormEvent) => {
    e.preventDefault();
    const body = draft.trim();
    if (!body || posting) return;
    setPosting(true);
    setDraft("");
    try {
      await addComment(body);
    } catch {
      setDraft(body);
      showToast({ kind: "error", message: "Couldn't post the comment" });
    } finally {
      setPosting(false);
    }
  };

  return (
    <article className="grid gap-0 overflow-hidden rounded-card border border-border bg-bg-elev md:grid-cols-[1.2fr_1fr]">
      <figure className="relative aspect-square bg-border/30">
        <Image
          src={media?.url ?? ""}
          alt={media?.alt_text ?? ""}
          fill
          sizes="(max-width: 768px) 100vw, 640px"
          className="object-cover"
        />
        {post.media.length > 1 ? (
          <>
            <IconButton
              aria-label="Previous image"
              className="absolute left-2 top-1/2 -translate-y-1/2 bg-bg/70"
              onClick={() => setSlide((s) => Math.max(0, s - 1))}
              disabled={slide === 0}
            >
              <ChevronLeft size={24} />
            </IconButton>
            <IconButton
              aria-label="Next image"
              className="absolute right-2 top-1/2 -translate-y-1/2 bg-bg/70"
              onClick={() =>
                setSlide((s) => Math.min(post.media.length - 1, s + 1))
              }
              disabled={slide === post.media.length - 1}
            >
              <ChevronRight size={24} />
            </IconButton>
            <figcaption className="sr-only">
              Image {slide + 1} of {post.media.length}
            </figcaption>
          </>
        ) : null}
      </figure>

      <div className="flex max-h-[640px] min-w-0 flex-col">
        <header className="flex items-center gap-2 border-b border-border px-4 py-3">
          {/* Avatar + username share one profile link — the avatar is never
              a dead zone (entity-navigation rule, Decided 2026-07-22). */}
          <Link
            href={`/dashboard/${post.designer.username}`}
            data-testid="detail-author-link"
            className="flex min-w-0 items-center gap-2"
          >
            <Avatar
              size={32}
              name={post.designer.display_name}
              src={post.designer.avatar_url}
              verified={post.designer.verified}
            />
            <span className="truncate text-body font-semibold text-text">
              {post.designer.username}
            </span>
          </Link>
          {onOverflow ? (
            <IconButton
              aria-label="More options"
              size="sm"
              className="ml-auto"
              onClick={() => onOverflow(post)}
            >
              <MoreHorizontal size={24} />
            </IconButton>
          ) : null}
        </header>

        <div className="min-h-0 flex-1 overflow-y-auto px-4 py-3">
          <p className="text-body text-text">
            <Link
              href={`/dashboard/${post.designer.username}`}
              className="pr-1 font-semibold"
            >
              {post.designer.username}
            </Link>
            {post.caption}
          </p>
          <p className="pt-1 text-caption text-text-2">
            {post.style_tags.map((t) => `#${t}`).join(" ")}
            {post.base_price_cents !== null
              ? ` · from ${formatNaira(post.base_price_cents)}`
              : " · quote on request"}
            {` · ${post.turnaround_days}d turnaround`}
          </p>

          {comments.length > 0 ? (
            <ul className="flex flex-col pt-3" aria-label="Comments">
              {comments.map((comment) => (
                <li key={comment.id}>
                  <CommentRow
                    comment={comment}
                    authorHref={`/dashboard/${comment.author.username}`}
                    posting={comment.id.startsWith("optimistic-")}
                  />
                </li>
              ))}
            </ul>
          ) : (
            <p className="pt-4 text-caption text-text-2">
              No comments yet — start the conversation.
            </p>
          )}
        </div>

        <footer className="flex flex-col gap-3 border-t border-border px-4 py-3">
          <ActionRow
            liked={post.liked}
            saved={post.saved}
            likeCount={post.like_count}
            onToggleLike={() =>
              toggleLike().catch(() =>
                showToast({
                  kind: "error",
                  message: "Couldn't like the post",
                  onRetry: () => void toggleLike(),
                }),
              )
            }
            onToggleSave={() => {
              const wasSaved = post.saved;
              toggleSave()
                .then(() => {
                  if (!wasSaved) {
                    maybeFirstSaveToast(showToast, account?.username ?? null);
                  }
                })
                .catch(() =>
                  showToast({
                    kind: "error",
                    message: "Couldn't save the post",
                  }),
                );
            }}
          />
          <p className="text-caption text-text-2">
            {formatAgo(post.created_at)}
          </p>
          {onRequest ? (
            <Button
              kind="gradient-primary"
              onClick={() => onRequest(post)}
              data-testid="detail-request-cta"
            >
              Request this outfit
            </Button>
          ) : null}
          <form className="flex items-center gap-2" onSubmit={submitComment}>
            <label htmlFor={`comment-${post.id}`} className="sr-only">
              Add a comment
            </label>
            <Input
              id={`comment-${post.id}`}
              placeholder="Add a comment…"
              value={draft}
              onChange={(e) => setDraft(e.target.value)}
              maxLength={500}
            />
            <Button
              kind="link"
              type="submit"
              disabled={draft.trim().length === 0 || posting}
            >
              Post
            </Button>
          </form>
        </footer>
      </div>
    </article>
  );
}
