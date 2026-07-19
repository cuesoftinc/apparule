"use client";

// B1 right column: own measurement-freshness card (MI-11) + suggested
// designers (Follow, MI-7). Renders from the vault + suggestions
// controllers; hidden below xl by the feed view.
import Link from "next/link";
import { formatAgo } from "@/lib/format";
import { useVault } from "@/controllers/use-vault";
import { useSuggestions } from "@/controllers/use-suggestions";
import { useAuth } from "@/controllers/auth/AuthContext";
import { Avatar } from "@/components/ui/Avatar";
import { Skeleton } from "@/components/ui/Skeleton";
import { Tooltip } from "@/components/ui/Tooltip";
import { UserRow } from "@/components/ui/UserRow";
import { useToasts } from "../toast-context";

const RING: Record<string, "gradient" | "amber" | "gray"> = {
  fresh: "gradient",
  aging: "amber",
  stale: "gray",
};

export function FeedSidebar({
  onUnfollow,
}: {
  /** Unfollow goes through the view's confirm sheet (MI-7). */
  onUnfollow: (username: string, unfollow: () => Promise<void>) => void;
}) {
  const { account } = useAuth();
  const vault = useVault();
  const suggestions = useSuggestions();
  const { showToast } = useToasts();

  const latestComplete = vault.sessions.find((s) => s.status === "complete");

  return (
    <aside
      aria-label="Your measurements and suggestions"
      className="flex w-80 flex-col gap-6"
    >
      <section
        aria-label="Measurement freshness"
        className="flex items-center gap-3"
      >
        {vault.loading ? (
          <Skeleton kind="avatar" />
        ) : (
          <>
            <Tooltip
              label={
                latestComplete
                  ? `Measured ${formatAgo(latestComplete.created_at)} ago — retake?`
                  : "No measurements yet"
              }
              placement="bottom"
            >
              <Link
                href="/dashboard/vault"
                aria-label="Open your measurement vault"
              >
                <Avatar
                  size={56}
                  name={account?.display_name ?? "You"}
                  ring={vault.freshness ? RING[vault.freshness] : "gray"}
                />
              </Link>
            </Tooltip>
            <div className="min-w-0">
              <p className="truncate text-body font-semibold text-text">
                {account?.username}
              </p>
              <p className="text-caption text-text-2">
                {latestComplete
                  ? `Measured ${formatAgo(latestComplete.created_at)} ago`
                  : "Add your measurements"}
              </p>
              <Link href="/dashboard/vault" className="text-caption text-link">
                {vault.freshness === "fresh" ? "Open vault" : "Retake now"}
              </Link>
            </div>
          </>
        )}
      </section>

      <section aria-label="Suggested designers" className="flex flex-col gap-1">
        <header className="flex items-baseline justify-between">
          <h2 className="text-body font-semibold text-text-2">
            Suggested for you
          </h2>
          <Link href="/dashboard/explore" className="text-caption text-link">
            See all
          </Link>
        </header>
        {suggestions.loading ? (
          <Skeleton kind="line" />
        ) : suggestions.rows.length === 0 ? (
          <p className="text-caption text-text-2">
            You follow everyone we know — explore for more.
          </p>
        ) : (
          <ul>
            {suggestions.rows.map((row) => (
              <li key={row.username}>
                <UserRow
                  username={row.username}
                  meta={row.meta ?? undefined}
                  verified={row.verified}
                  trailing={row.viewer_follows ? "following" : "follow"}
                  onFollow={() =>
                    suggestions.toggleFollow(row).catch(() =>
                      showToast({
                        kind: "error",
                        message: `Couldn't follow ${row.username}`,
                        onRetry: () => void suggestions.toggleFollow(row),
                      }),
                    )
                  }
                  onFollowingTap={() =>
                    onUnfollow(row.username, () =>
                      suggestions.toggleFollow(row),
                    )
                  }
                  onOpen={() =>
                    window.location.assign(`/dashboard/${row.username}`)
                  }
                />
              </li>
            ))}
          </ul>
        )}
      </section>
    </aside>
  );
}
