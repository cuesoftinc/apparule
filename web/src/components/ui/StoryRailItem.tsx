"use client";

// StoryRailItem — design.md §8.2: state unseen (gradient) / seen (gray) /
// loading (rotating, MI-8: subtle 1.5s ring rotation while content loads).
// Geometry (Figma master, design.md [Decided 2026-07-19]): 64px ring frame
// wrapping a 56px photo — 2px stroke + 2px clear gap.
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
        // story preloads (MI-8) — same 64px frame / 56px photo geometry as
        // the solid rings.
        <span className="relative grid size-16 place-items-center">
          <svg
            viewBox="0 0 64 64"
            aria-hidden
            className="absolute inset-0 size-full animate-[spin_1.5s_linear_infinite] motion-reduce:animate-none"
          >
            <defs>
              <linearGradient
                id={ringGradientId}
                x1="0%"
                y1="0%"
                x2="100%"
                y2="100%"
              >
                <stop offset="0%" stopColor="var(--ap-accent-start)" />
                <stop offset="100%" stopColor="var(--ap-accent-end)" />
              </linearGradient>
            </defs>
            <circle
              cx="32"
              cy="32"
              r="31"
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
          size={64}
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
