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
  /**
   * Eager-load the media with fetchpriority=high — reserved for the one
   * above-the-fold LCP candidate (the hero phone mock's first feed post,
   * the audited mobile LCP element). Everything else stays lazy.
   */
  mediaPriority?: boolean;
  /** next/image `sizes` override for scaled contexts (e.g. the hero mock). */
  mediaSizes?: string;
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
  mediaPriority = false,
  mediaSizes = "(max-width: 768px) 100vw, 630px",
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
      {/* header — Figma master (52:462): px 12 / py 8 / gap 8 */}
      <header className="flex items-center gap-2 px-3 py-2">
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

      {/* media (full-bleed, 1:1 default / 4:5 max). The onClick here is the
          MI-1 double-tap GESTURE zone, not a control: single click does
          nothing, the accessible like path is the ActionRow heart, and a
          role="button" would announce a control that ignores activation —
          while a real <button> can't own the nested carousel buttons. It
          stays a plain div (exempt from the cursor-affordance base rule by
          design). */}
      <div
        className="relative aspect-square w-full select-none overflow-hidden bg-border/30"
        onClick={handleMediaTap}
        data-testid="post-media"
      >
        <Image
          src={media[Math.min(slide, media.length - 1)]?.url ?? ""}
          alt={media[Math.min(slide, media.length - 1)]?.alt_text ?? ""}
          fill
          priority={mediaPriority}
          // Next 16 splits the props: `priority` alone de-lazies + preloads
          // but no longer emits the img-level hint.
          fetchPriority={mediaPriority ? "high" : undefined}
          sizes={mediaSizes}
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
        {/* MI-4 carousel: count pill (Figma 52:368) + desktop hover chevrons */}
        {media.length > 1 ? (
          <>
            <span
              data-testid="carousel-count"
              className="tnum absolute right-3 top-3 flex h-[22px] items-center rounded-pill bg-text px-2 text-micro font-semibold text-bg"
            >
              {slide + 1}/{media.length}
            </span>
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
          </>
        ) : null}
      </div>

      {/* Figma master: progress dots sit below the media, not over it */}
      {media.length > 1 ? (
        <div
          data-testid="carousel-dots"
          className="flex w-full justify-center gap-1 pt-2.5"
        >
          {media.map((m, i) => (
            <span
              key={m.id}
              className={clsx(
                "rounded-pill transition-all duration-120 ease-standard",
                i === slide
                  ? "size-1.5 bg-accent-gradient" // active dot 6px, gradient
                  : "size-1 bg-border",
              )}
            />
          ))}
        </div>
      ) : null}

      {/* action row */}
      <ActionRow
        liked={post.liked}
        saved={post.saved}
        likeCount={post.like_count}
        onToggleLike={() => onToggleLike?.()}
        onToggleSave={() => onToggleSave?.()}
        onComment={onComment}
        onShare={onShare}
        className="px-1.5 pt-1"
      />

      {/* like count + caption + comments + CTA + timestamp — Figma master:
          one px-16 column at 4px rhythm, semibold caption, inline "more" */}
      <div className="flex flex-col items-start gap-1 px-4">
        <span className="tnum text-body font-semibold text-text">
          {post.like_count.toLocaleString("en-NG")} likes
        </span>
        <p
          className={clsx(
            "text-body font-semibold text-text",
            !captionOpen && "line-clamp-2",
          )}
        >
          {post.designer.username} {post.caption}
          {!captionOpen && post.caption.length > 80 ? (
            <>
              {" "}
              <button
                type="button"
                onClick={() => setCaptionOpen(true)}
                className="font-normal text-text-2"
              >
                more
              </button>
            </>
          ) : null}
        </p>
        {post.comment_count > 0 ? (
          <button
            type="button"
            onClick={onComment}
            className="w-fit text-body text-text-2"
          >
            View all {post.comment_count} comments
          </button>
        ) : null}
        {/* request CTA — full-width quiet button on designer posts */}
        {showCta ? (
          <Button kind="quiet" size="md" className="w-full" onClick={onRequest}>
            Request this outfit
          </Button>
        ) : null}
        {/* suppressHydrationWarning: relative timestamps are computed at
            render time and may differ between server and client by design */}
        <time
          dateTime={post.created_at}
          suppressHydrationWarning
          className="text-micro uppercase tracking-[0.4px] text-text-2"
        >
          {formatAgo(post.created_at)}
        </time>
      </div>
    </article>
  );
}
