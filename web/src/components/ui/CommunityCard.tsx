// CommunityCard — design.md §8.2b Home section kit: Discord card. Accuracy
// standard (2026-07-18): the master carries a neutral badge — no member
// count on canvases; the live count arrives at runtime (null → neutral).
import clsx from "clsx";
import { Users } from "lucide-react";
import { DiscordMark } from "@/components/icons/DiscordMark";
import { Button } from "./Button";

export interface CommunityCardProps {
  /** Live member count fetched at runtime; null renders the neutral badge. */
  memberCount?: number | null;
  discordHref?: string;
  className?: string;
}

export function CommunityCard({
  memberCount = null,
  discordHref = "https://discord.gg/cuesoft",
  className,
}: CommunityCardProps) {
  return (
    <div
      className={clsx(
        "flex w-full max-w-sm flex-col gap-4 rounded-card border border-border bg-bg-elev p-6",
        className,
      )}
    >
      <div className="flex items-center gap-3">
        <span className="grid size-11 place-items-center rounded-pill bg-accent-gradient text-on-accent">
          <DiscordMark size={22} />
        </span>
        <div>
          <p className="text-body-lg font-semibold text-text">Join the community</p>
          <p
            data-testid="member-badge"
            className="flex items-center gap-1 text-caption text-text-2"
          >
            <Users size={14} />
            {memberCount === null ? (
              "Discord"
            ) : (
              <span className="tnum">
                {memberCount.toLocaleString("en-NG")} members
              </span>
            )}
          </p>
        </div>
      </div>
      <p className="text-body text-text-2">
        Builders, designers, and tailors shaping open-source fashion tech —
        roadmap talk, capture-QC debugging, and show-and-tell.
      </p>
      <Button kind="quiet" size="sm" onClick={() => window.open(discordHref, "_blank")}>
        Join Discord
      </Button>
    </div>
  );
}
