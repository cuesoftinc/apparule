"use client";

// PostCard — design.md §3 anatomy + §8.2: media single / carousel (dots) ·
// CTA with/without "Request this outfit" · state default / skeleton.
// Anatomy: header (avatar, username, badge, ⋯) · media carousel (MI-4) ·
// action row (MI-1/2/3) · like count · caption (2-line clamp, "more") ·
// request CTA (full-width quiet button — Apparule's one IG addition) ·
// timestamp. MI-1: double-tap/double-click media → 96px heart burst + like.
import { useRef, useState } from "react";
import clsx from "clsx";
import Image from "next/image";
import { ChevronLeft, ChevronRight, Heart, MoreHorizontal } from "lucide-react";
import type { Post } from "@/models";
import { formatAgo } from "@/lib/format";
import { ActionRow } from "./ActionRow";
import { Avatar } from "./Avatar";
import { Button } from "./Button";
import { IconButton } from "./IconButton";
import { Skeleton } from "./Skeleton";

export interface PostCardProps {
  post?: Post;
  /** skeleton state renders the §3 placeholder anatomy (MI-19). */
  skeleton?: boolean;
  onToggleLike?: () => void;
  onToggleSave?: () => void;
  onRequest?: () => void;
  onComment?: () => void;
  onShare?: () => void;
  onOverflow?: () => void;
  className?: string;
}

export function PostCard({
  post,
  skeleton = false,
  onToggleLike,
  onToggleSave,
  onRequest,
  onComment,
  onShare,
  onOverflow,
  className,
}: PostCardProps) {
  const [slide, setSlide] = useState(0);
  const [bigHeart, setBigHeart] = useState(false);
  const [captionOpen, setCaptionOpen] = useState(false);
  const lastTap = useRef(0);

  if (skeleton || !post) {
    return <Skeleton kind="card" className={className} />;
  }

  const media = post.media;
  const showCta = onRequest !== undefined;

  // MI-1 double-tap to like (double-click on desktop): heart burst + fill.
  const handleMediaTap = () => {
    const now = Date.now();
    if (now - lastTap.current < 300) {
      if (!post.liked) onToggleLike?.();
      setBigHeart(true);
      setTimeout(() => setBigHeart(false), 700);
    }
    lastTap.current = now;
  };

  return (
    <article
      data-testid="post-card"
      className={clsx(
        "flex w-full max-w-[630px] flex-col border-b border-border bg-bg pb-3",
        className,
      )}
    >
      {/* header */}
      <header className="flex items-center gap-3 px-4 py-3">
        <Avatar
          size={32}
          name={post.designer.display_name}
          src={post.designer.avatar_url}
          verified={post.designer.verified}
        />
        <span className="text-body font-semibold text-text">
          {post.designer.username}
        </span>
        <IconButton
          aria-label="More options"
          size="sm"
          className="ml-auto"
          onClick={onOverflow}
        >
          <MoreHorizontal size={24} />
        </IconButton>
      </header>

      {/* media (full-bleed, 1:1 default / 4:5 max) */}
      <div
        className="relative aspect-square w-full select-none overflow-hidden bg-border/30"
        onClick={handleMediaTap}
        data-testid="post-media"
      >
        <Image
          src={media[Math.min(slide, media.length - 1)]?.url ?? ""}
          alt={media[Math.min(slide, media.length - 1)]?.alt_text ?? ""}
          fill
          sizes="(max-width: 768px) 100vw, 630px"
          className="object-cover"
        />
        {bigHeart ? (
          <span className="pointer-events-none absolute inset-0 grid place-items-center">
            <Heart
              size={96}
              data-testid="big-heart"
              className="fill-white text-white drop-shadow-lg animate-[big-heart_700ms_var(--ap-ease-standard)_forwards] motion-reduce:animate-none"
            />
          </span>
        ) : null}
        {/* MI-4 carousel: desktop hover chevrons + progress dots */}
        {media.length > 1 ? (
          <>
            {slide > 0 ? (
              <button
                type="button"
                aria-label="Previous image"
                onClick={(e) => {
                  e.stopPropagation();
                  setSlide((s) => s - 1);
                }}
                className="absolute left-2 top-1/2 grid size-7 -translate-y-1/2 place-items-center rounded-pill bg-bg-elev/90 text-text shadow-sm"
              >
                <ChevronLeft size={16} />
              </button>
            ) : null}
            {slide < media.length - 1 ? (
              <button
                type="button"
                aria-label="Next image"
                onClick={(e) => {
                  e.stopPropagation();
                  setSlide((s) => s + 1);
                }}
                className="absolute right-2 top-1/2 grid size-7 -translate-y-1/2 place-items-center rounded-pill bg-bg-elev/90 text-text shadow-sm"
              >
                <ChevronRight size={16} />
              </button>
            ) : null}
            <div
              data-testid="carousel-dots"
              className="absolute inset-x-0 bottom-2 flex justify-center gap-1"
            >
              {media.map((m, i) => (
                <span
                  key={m.id}
                  className={clsx(
                    "rounded-pill transition-all duration-120 ease-standard",
                    i === slide
                      ? "size-1.5 bg-accent-gradient" // active dot 6px, gradient
                      : "size-1 bg-white/70",
                  )}
                />
              ))}
            </div>
          </>
        ) : null}
      </div>

      {/* action row */}
      <ActionRow
        liked={post.liked}
        saved={post.saved}
        likeCount={post.like_count}
        onToggleLike={() => onToggleLike?.()}
        onToggleSave={() => onToggleSave?.()}
        onComment={onComment}
        onShare={onShare}
        className="px-2 pt-1"
      />

      {/* like count + caption + comments + timestamp */}
      <div className="flex flex-col gap-1 px-4">
        <span className="tnum text-body font-semibold text-text">
          {post.like_count.toLocaleString("en-NG")} likes
        </span>
        <p className={clsx("text-body text-text", !captionOpen && "line-clamp-2")}>
          <span className="font-semibold">{post.designer.username}</span>{" "}
          {post.caption}
        </p>
        {!captionOpen && post.caption.length > 80 ? (
          <button
            type="button"
            onClick={() => setCaptionOpen(true)}
            className="w-fit text-body text-text-2"
          >
            more
          </button>
        ) : null}
        {post.comment_count > 0 ? (
          <button
            type="button"
            onClick={onComment}
            className="w-fit text-body text-text-2"
          >
            View all {post.comment_count} comments
          </button>
        ) : null}
      </div>

      {/* request CTA — full-width quiet button on designer posts */}
      {showCta ? (
        <div className="px-4 pt-3">
          <Button kind="quiet" size="md" className="w-full" onClick={onRequest}>
            Request this outfit
          </Button>
        </div>
      ) : null}

      <time
        dateTime={post.created_at}
        className="px-4 pt-2 text-micro uppercase text-text-2"
      >
        {formatAgo(post.created_at)}
      </time>
    </article>
  );
}
