"use client";

// CommunityCard — design.md §8.2b Home section kit: Discord card, compact
// horizontal master 144:3724 (enriched landing): icon/brand-discord 32 ·
// title + member line · Join CTA. Accuracy standard (2026-07-18): no
// invented member counts — the live count arrives at runtime (null →
// neutral copy, count rendered only when real).
import clsx from "clsx";
import { DiscordMark } from "@/components/icons/DiscordMark";
import { Button } from "./Button";

export interface CommunityCardProps {
  /** Live member count fetched at runtime; null renders the neutral line. */
  memberCount?: number | null;
  discordHref?: string;
  className?: string;
}

export function CommunityCard({
  memberCount = null,
  discordHref = "https://discord.gg/CDfZxxrxbb",
  className,
}: CommunityCardProps) {
  return (
    <div
      className={clsx(
        // Figma master: gap 14 / pl 20 / pr 16 / py 16 — master geometry
        "flex w-full max-w-[440px] items-center gap-3.5 rounded-card border border-border bg-bg-elev py-4 pl-5 pr-4",
        className,
      )}
    >
      {/* Discord brand blurple — documented raw-hex exception (brand glyph
          color, not a UI token; identical both themes, as on the canvas) */}
      <DiscordMark size={32} className="shrink-0 text-[#5865F2]" />
      <div className="min-w-0 flex-1">
        <p className="truncate text-body-lg font-semibold text-text">
          Join the apparule Discord
        </p>
        <p
          data-testid="member-badge"
          className="truncate text-body text-text-2"
        >
          {memberCount === null ? (
            <>Fit checks &amp; dev chat, daily</>
          ) : (
            <>
              <span className="tnum">
                {memberCount.toLocaleString("en-NG")} members
              </span>
              {" · fit checks & dev chat, daily"}
            </>
          )}
        </p>
      </div>
      <Button
        kind="gradient-primary"
        size="sm"
        aria-label="Join Discord"
        className="shrink-0"
        onClick={() => window.open(discordHref, "_blank", "noopener")}
      >
        Join
      </Button>
    </div>
  );
}
