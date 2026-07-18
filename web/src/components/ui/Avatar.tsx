"use client";

// Avatar — design.md §8.2: size 32 / 44 / 56 / 96 · ring: none / gradient
// (fresh) / amber / gray · badge: none / designer-verified. Ring semantics:
// story ring (MI-8) and measurement-freshness ring (MI-11) share this atom.
// Initials render when no image URL is provided.
import clsx from "clsx";
import Image from "next/image";
import { BadgeCheck } from "lucide-react";

export type AvatarSize = 32 | 44 | 56 | 96;
export type AvatarRing = "none" | "gradient" | "amber" | "gray";

export interface AvatarProps {
  size?: AvatarSize;
  ring?: AvatarRing;
  verified?: boolean;
  src?: string | null;
  /** Display or user name — drives alt text + initials fallback. */
  name: string;
  className?: string;
}

function initials(name: string): string {
  return name
    .split(/[\s._-]+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase())
    .join("");
}

export function Avatar({
  size = 44,
  ring = "none",
  verified = false,
  src,
  name,
  className,
}: AvatarProps) {
  const dimension = { width: size, height: size };
  return (
    <span
      data-ring={ring}
      data-size={size}
      className={clsx("relative inline-block", className)}
    >
      <span
        className={clsx(
          "grid place-items-center rounded-pill",
          ring !== "none" && "p-[2px]", // 2px ring (MI-8)
          ring === "gradient" && "bg-accent-gradient",
          ring === "amber" && "bg-warn",
          ring === "gray" && "bg-border",
        )}
        style={ring === "none" ? undefined : undefined}
      >
        {src ? (
          <Image
            src={src}
            alt={name}
            {...dimension}
            className={clsx(
              "rounded-pill object-cover",
              ring !== "none" && "border-2 border-bg",
            )}
          />
        ) : (
          <span
            role="img"
            aria-label={name}
            style={dimension}
            className={clsx(
              "grid select-none place-items-center rounded-pill bg-border/60 font-semibold text-text",
              ring !== "none" && "border-2 border-bg",
              size >= 96
                ? "text-title"
                : size >= 56
                  ? "text-body-lg"
                  : "text-caption",
            )}
          >
            {initials(name)}
          </span>
        )}
      </span>
      {verified ? (
        <span
          data-testid="verified-badge"
          title="Verified designer"
          className="absolute -bottom-0.5 -right-0.5 grid place-items-center rounded-pill bg-bg"
        >
          <BadgeCheck
            size={size >= 56 ? 18 : 14}
            className="fill-link text-bg"
            aria-label="Verified designer"
          />
        </span>
      ) : null}
    </span>
  );
}
