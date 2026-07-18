"use client";

// StoryRailItem — design.md §8.2: state unseen (gradient) / seen (gray) /
// loading (rotating, MI-8: subtle 1.5s ring rotation while content loads).
import { useId } from "react";
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
  const ringGradientId = useId();
  return (
    <button
      type="button"
      onClick={onClick}
      data-state={state}
      className={clsx("flex w-16 flex-col items-center gap-1", className)}
    >
      {state === "loading" ? (
        // Figma master (46:88): dashed gradient ring, rotating while the
        // story preloads (MI-8).
        <span className="relative inline-grid place-items-center p-[2px]">
          <svg
            viewBox="0 0 60 60"
            aria-hidden
            className="absolute inset-0 size-full animate-[spin_1.5s_linear_infinite] motion-reduce:animate-none"
          >
            <defs>
              <linearGradient id={ringGradientId} x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" stopColor="var(--ap-accent-start)" />
                <stop offset="100%" stopColor="var(--ap-accent-end)" />
              </linearGradient>
            </defs>
            <circle
              cx="30"
              cy="30"
              r="29"
              fill="none"
              stroke={`url(#${ringGradientId})`}
              strokeWidth="2"
              strokeLinecap="round"
              strokeDasharray="6 7"
            />
          </svg>
          <Avatar size={56} name={username} src={avatarUrl} ring="none" />
        </span>
      ) : (
        <Avatar
          size={56}
          name={username}
          src={avatarUrl}
          ring={state === "seen" ? "gray" : "gradient"}
        />
      )}
      <span className="w-full truncate text-center text-micro text-text-2">
        {username}
      </span>
    </button>
  );
}
