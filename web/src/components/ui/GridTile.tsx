"use client";

// GridTile — design.md §8.2b: ratio 1:1 · state default / hover-stats
// (♥ + 💬 counts overlay, 120ms fade) / skeleton · corner badge: none /
// carousel. Explore masonry + profile grids.
import clsx from "clsx";
import Image from "next/image";
import { Copy, Heart, MessageCircle } from "lucide-react";
import { Skeleton } from "./Skeleton";

export interface GridTileProps {
  src?: string;
  alt?: string;
  likeCount?: number;
  commentCount?: number;
  carousel?: boolean;
  skeleton?: boolean;
  onClick?: () => void;
  className?: string;
}

export function GridTile({
  src,
  alt = "",
  likeCount = 0,
  commentCount = 0,
  carousel = false,
  skeleton = false,
  onClick,
  className,
}: GridTileProps) {
  if (skeleton || !src) {
    return <Skeleton kind="media" className={clsx("rounded-none", className)} />;
  }
  return (
    <button
      type="button"
      onClick={onClick}
      data-carousel={carousel || undefined}
      className={clsx(
        "group relative aspect-square w-full overflow-hidden bg-border/30",
        className,
      )}
    >
      <Image src={src} alt={alt} fill sizes="(max-width: 768px) 33vw, 300px" className="object-cover" />
      {carousel ? (
        <span
          data-testid="carousel-badge"
          className="absolute right-2 top-2 text-white drop-shadow"
        >
          <Copy size={16} className="scale-x-[-1]" />
        </span>
      ) : null}
      {/* hover-stats overlay — 120ms fade */}
      <span
        data-testid="hover-stats"
        className={clsx(
          "absolute inset-0 flex items-center justify-center gap-6 bg-black/40 text-white",
          "opacity-0 transition-opacity duration-120 ease-standard group-hover:opacity-100 group-focus-visible:opacity-100",
          "motion-reduce:transition-none",
        )}
      >
        <span className="tnum flex items-center gap-1.5 font-semibold">
          <Heart size={18} className="fill-white" /> {likeCount.toLocaleString("en-NG")}
        </span>
        <span className="tnum flex items-center gap-1.5 font-semibold">
          <MessageCircle size={18} className="fill-white" /> {commentCount.toLocaleString("en-NG")}
        </span>
      </span>
    </button>
  );
}
