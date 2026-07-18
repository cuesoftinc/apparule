"use client";

// UserRow — design.md §8.2b: avatar 32/44 + username + meta line ·
// trailing: Follow (gradient) / Following (quiet) / none. MI-7: Follow
// morphs 150ms to quiet "Following"; unfollow only via confirm (the view
// opens the confirm sheet — this row never unfollows directly).
import clsx from "clsx";
import { Avatar } from "./Avatar";
import { Button } from "./Button";

export type UserRowTrailing = "follow" | "following" | "none";

export interface UserRowProps {
  username: string;
  meta?: string;
  avatarUrl?: string | null;
  avatarSize?: 32 | 44;
  verified?: boolean;
  trailing?: UserRowTrailing;
  onFollow?: () => void;
  /** "Following" tap → the view's unfollow confirm sheet (MI-7). */
  onFollowingTap?: () => void;
  onOpen?: () => void;
  className?: string;
}

export function UserRow({
  username,
  meta,
  avatarUrl,
  avatarSize = 44,
  verified = false,
  trailing = "none",
  onFollow,
  onFollowingTap,
  onOpen,
  className,
}: UserRowProps) {
  return (
    <div
      data-trailing={trailing}
      className={clsx("flex w-full items-center gap-3 py-2", className)}
    >
      <button type="button" onClick={onOpen} className="flex min-w-0 flex-1 items-center gap-3 text-left">
        <Avatar size={avatarSize} name={username} src={avatarUrl} verified={verified} />
        <span className="min-w-0">
          <span className="block truncate text-body font-semibold text-text">
            {username}
          </span>
          {meta ? (
            <span className="block truncate text-caption text-text-2">{meta}</span>
          ) : null}
        </span>
      </button>
      {trailing === "follow" ? (
        <Button
          kind="gradient-primary"
          size="sm"
          onClick={onFollow}
          className="transition-all duration-150 ease-standard"
        >
          Follow
        </Button>
      ) : trailing === "following" ? (
        <Button
          kind="quiet"
          size="sm"
          onClick={onFollowingTap}
          className="transition-all duration-150 ease-standard"
        >
          Following
        </Button>
      ) : null}
    </div>
  );
}
