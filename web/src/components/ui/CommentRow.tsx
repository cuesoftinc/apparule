"use client";

// CommentRow — design.md §8.2b: avatar 32 + username + text + timestamp +
// like heart · state default / liked / posting-optimistic (MI-18) /
// reply-indent.
import clsx from "clsx";
import { Heart } from "lucide-react";
import type { Comment } from "@/models";
import { formatAgo } from "@/lib/format";
import { Avatar } from "./Avatar";

export interface CommentRowProps {
  comment: Comment;
  /** MI-18: renders dimmed while the optimistic post is in flight. */
  posting?: boolean;
  replyIndent?: boolean;
  onToggleLike?: () => void;
  onReply?: () => void;
  className?: string;
}

export function CommentRow({
  comment,
  posting = false,
  replyIndent = false,
  onToggleLike,
  onReply,
  className,
}: CommentRowProps) {
  return (
    <div
      data-posting={posting || undefined}
      data-liked={comment.liked || undefined}
      className={clsx(
        "flex items-start gap-3 py-2",
        replyIndent && "pl-11",
        posting && "opacity-50",
        className,
      )}
    >
      <Avatar
        size={32}
        name={comment.author.username}
        src={comment.author.avatar_url}
      />
      <div className="min-w-0 flex-1">
        {/* Figma master (92:1077): the comment text stays visible while
            posting; the meta line reads "Posting…" */}
        <p className="text-body text-text">
          <span className="font-semibold">{comment.author.username}</span>{" "}
          {comment.body}
        </p>
        <div className="mt-1 flex items-center gap-4 text-micro text-text-2">
          {posting ? (
            <span>Posting…</span>
          ) : (
            <>
              <time dateTime={comment.created_at}>
                {formatAgo(comment.created_at)}
              </time>
              {comment.like_count > 0 ? (
                <span className="tnum">{comment.like_count} likes</span>
              ) : null}
              {onReply ? (
                <button
                  type="button"
                  onClick={onReply}
                  className="font-semibold"
                >
                  Reply
                </button>
              ) : null}
            </>
          )}
        </div>
      </div>
      <button
        type="button"
        aria-label={comment.liked ? "Unlike comment" : "Like comment"}
        aria-pressed={comment.liked}
        onClick={onToggleLike}
        disabled={posting}
        className="mt-1 shrink-0 text-text-2"
      >
        <Heart
          size={14}
          className={comment.liked ? "fill-like text-like" : undefined}
        />
      </button>
    </div>
  );
}
