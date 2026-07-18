"use client";

// Avatar — design.md §8.2: size 32 / 44 / 56 / 96 · ring: none / gradient
// (fresh) / amber / gray · badge: none / designer-verified. Ring semantics:
// story ring (MI-8) and measurement-freshness ring (MI-11) share this atom.
// Initials render when no image URL is provided.
import clsx from "clsx";
import Image from "next/image";
import { Check } from "lucide-react";

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
              // Figma master (42:189): solid border-token fill, text-2
              // initials (12px at 32 → 28px at 96).
              "grid select-none place-items-center rounded-pill bg-border font-semibold text-text-2",
              ring !== "none" && "border-2 border-bg",
              size >= 96
                ? "text-[28px]"
                : size >= 56
                  ? "text-body-lg"
                  : size >= 44
                    ? "text-body"
                    : "text-micro",
            )}
          >
            {initials(name)}
          </span>
        )}
      </span>
      {verified ? (
        // Figma master: accent-gradient disc, 2px bg keyline, white check,
        // flush to the bottom-right corner (14px at 32/44 → 28px at 96).
        <span
          data-testid="verified-badge"
          title="Verified designer"
          className={clsx(
            "absolute bottom-0 right-0 grid place-items-center rounded-pill border-2 border-bg bg-accent-gradient text-on-accent",
            size >= 96 ? "size-7" : size >= 56 ? "size-5" : "size-3.5",
          )}
        >
          <Check
            size={size >= 96 ? 17 : size >= 56 ? 12 : 8}
            strokeWidth={3}
            aria-label="Verified designer"
          />
        </span>
      ) : null}
    </span>
  );
}
