"use client";

// NotificationRow — design.md §8.2b: kind like / follow / comment / quote /
// status-change / payout · state unread / read · trailing: post thumb /
// Follow button / none.
import clsx from "clsx";
import Image from "next/image";
import type { Notification } from "@/models";
import { formatAgo } from "@/lib/format";
import { Avatar } from "./Avatar";
import { Button } from "./Button";

export interface NotificationRowProps {
  notification: Notification;
  onOpen?: () => void;
  /** follow-kind rows render the Follow trailing action (MI-7). */
  onFollowBack?: () => void;
  className?: string;
}

export function NotificationRow({
  notification,
  onOpen,
  onFollowBack,
  className,
}: NotificationRowProps) {
  const unread = notification.read_at === null;
  return (
    <div
      data-kind={notification.kind}
      data-unread={unread || undefined}
      className={clsx(
        "flex w-full items-center gap-3 px-4 py-3",
        unread && "bg-accent-start/5",
        className,
      )}
    >
      <button
        type="button"
        onClick={onOpen}
        className="flex min-w-0 flex-1 items-center gap-3 text-left"
      >
        {unread ? (
          <span
            data-testid="unread-dot"
            className="size-2 shrink-0 rounded-pill bg-accent-gradient"
          />
        ) : (
          <span className="size-2 shrink-0" />
        )}
        {notification.actor ? (
          <Avatar
            size={44}
            name={notification.actor.username}
            src={notification.actor.avatar_url}
          />
        ) : null}
        <span className="min-w-0 flex-1">
          {/* Figma master (92:1208): the actor name is semibold, the action
              copy stays regular in both read states. */}
          <span className="block text-body text-text">
            {notification.actor ? (
              <span className="font-semibold">
                {notification.actor.username}{" "}
              </span>
            ) : null}
            {notification.actor &&
            notification.text.startsWith(notification.actor.username)
              ? notification.text.slice(notification.actor.username.length + 1)
              : notification.text}
          </span>
          <time
            dateTime={notification.created_at}
            className="text-micro text-text-2"
          >
            {formatAgo(notification.created_at)}
          </time>
        </span>
      </button>
      {notification.kind === "follow" && onFollowBack ? (
        <Button kind="gradient-primary" size="sm" onClick={onFollowBack}>
          Follow
        </Button>
      ) : notification.thumb_url ? (
        <span className="relative size-11 shrink-0 overflow-hidden rounded-card bg-border/40">
          <Image
            src={notification.thumb_url}
            alt=""
            fill
            sizes="44px"
            className="object-cover"
          />
        </span>
      ) : null}
    </div>
  );
}
