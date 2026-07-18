"use client";

// ActionRow — design.md §8.2 (as built): liked false/true · saved
// false/true — the PostCard action row (♥ 💬 ↗ ⌁save).
// MI-2: like tap scales 1→0.8→1.15→1 (240ms spring), outline→filled like
// red; unlike has no animation (IG asymmetry). MI-3: save dips −4px then
// fills. State changes announced via aria-live (design.md §5).
import { useState } from "react";
import clsx from "clsx";
import { Bookmark, Heart, MessageCircle, Send } from "lucide-react";
import { IconButton } from "./IconButton";

export interface ActionRowProps {
  liked: boolean;
  saved: boolean;
  likeCount: number;
  onToggleLike: () => void;
  onToggleSave: () => void;
  onComment?: () => void;
  onShare?: () => void;
  className?: string;
}

export function ActionRow({
  liked,
  saved,
  likeCount,
  onToggleLike,
  onToggleSave,
  onComment,
  onShare,
  className,
}: ActionRowProps) {
  const [likeBurst, setLikeBurst] = useState(false);
  const [saveDip, setSaveDip] = useState(false);

  return (
    <div
      data-liked={liked}
      data-saved={saved}
      className={clsx("flex items-center", className)}
    >
      <IconButton
        aria-label={liked ? "Unlike" : "Like"}
        aria-pressed={liked}
        onClick={() => {
          if (!liked) {
            // MI-2: animate on like only (IG asymmetry)
            setLikeBurst(true);
            setTimeout(() => setLikeBurst(false), 240);
          }
          onToggleLike();
        }}
      >
        <Heart
          size={24}
          className={clsx(
            liked ? "fill-like text-like" : "text-text",
            likeBurst &&
              "animate-[like-burst_240ms_var(--ap-ease-standard)] motion-reduce:animate-none",
          )}
        />
      </IconButton>
      <IconButton aria-label="Comments" onClick={onComment}>
        <MessageCircle size={24} className="text-text" />
      </IconButton>
      <IconButton aria-label="Share" onClick={onShare}>
        <Send size={24} className="text-text" />
      </IconButton>
      <span aria-live="polite" className="sr-only">
        {liked ? `Liked. ${likeCount} likes` : `${likeCount} likes`}
      </span>
      <IconButton
        aria-label={saved ? "Remove from saved" : "Save"}
        aria-pressed={saved}
        className="ml-auto"
        onClick={() => {
          setSaveDip(true);
          setTimeout(() => setSaveDip(false), 200);
          onToggleSave();
        }}
      >
        <Bookmark
          size={24}
          className={clsx(
            saved ? "fill-text text-text" : "text-text",
            saveDip &&
              "animate-[save-dip_200ms_var(--ap-ease-standard)] motion-reduce:animate-none",
          )}
        />
      </IconButton>
    </div>
  );
}
