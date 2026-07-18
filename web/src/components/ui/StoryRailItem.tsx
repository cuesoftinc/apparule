"use client";

// StoryRailItem — design.md §8.2: state unseen (gradient) / seen (gray) /
// loading (rotating, MI-8: subtle 1.5s ring rotation while content loads).
import clsx from "clsx";
import { Avatar } from "./Avatar";

export type StoryRailItemState = "unseen" | "seen" | "loading";

export interface StoryRailItemProps {
  username: string;
  avatarUrl?: string | null;
  state?: StoryRailItemState;
  onClick?: () => void;
  className?: string;
}

export function StoryRailItem({
  username,
  avatarUrl,
  state = "unseen",
  onClick,
  className,
}: StoryRailItemProps) {
  return (
    <button
      type="button"
      onClick={onClick}
      data-state={state}
      className={clsx("flex w-16 flex-col items-center gap-1", className)}
    >
      <span
        className={clsx(
          state === "loading" &&
            "animate-[spin_1.5s_linear_infinite] motion-reduce:animate-none",
          "rounded-pill",
        )}
      >
        <Avatar
          size={56}
          name={username}
          src={avatarUrl}
          ring={state === "seen" ? "gray" : "gradient"}
        />
      </span>
      <span className="w-full truncate text-center text-micro text-text">
        {username}
      </span>
    </button>
  );
}
