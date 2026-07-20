"use client";

// B2 — Explore/Discover: search bar with recent-searches dropdown · filter
// chips (style tags + price bands, api.md §5) · masonry grid (GridTile
// hover-stats) · click → post modal (IG desktop pattern) · submitted
// search → sectioned results (Designers above Posts). Render-only over
// useExplore.
import { useMemo, useState, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import type { Post } from "@/models";
import { useExplore } from "@/controllers/use-explore";
import { Chip } from "@/components/ui/Chip";
import { EmptyState } from "@/components/ui/EmptyState";
import { GridTile } from "@/components/ui/GridTile";
import { Input } from "@/components/ui/Input";
import { Sheet } from "@/components/ui/Sheet";
import { Skeleton } from "@/components/ui/Skeleton";
import { UserRow } from "@/components/ui/UserRow";
import { PostDetailView } from "../post/PostDetailView";
import { PostOptionsSheet } from "../feed/PostOptionsSheet";
import { RequestStepperSheet } from "../feed/RequestStepperSheet";
import {
  UnfollowConfirmSheet,
  type UnfollowTarget,
} from "../UnfollowConfirmSheet";
import { useToasts } from "../toast-context";

const PRICE_BANDS = [
  { value: "budget", label: "Under ₦25k" },
  { value: "mid", label: "₦25k–₦100k" },
  { value: "premium", label: "Over ₦100k" },
] as const;

// Turnaround-time chips (pages.md B2) — single-select max-days buckets.
const TURNAROUNDS = [
  { value: 7, label: "≤ 1 week" },
  { value: 14, label: "≤ 2 weeks" },
  { value: 30, label: "≤ 1 month" },
] as const;

export function ExploreView() {
  const router = useRouter();
  const explore = useExplore();
  const { showToast } = useToasts();
  const [openPostId, setOpenPostId] = useState<string | null>(null);
  const [requestPost, setRequestPost] = useState<Post | null>(null);
  const [optionsPost, setOptionsPost] = useState<Post | null>(null);
  const [searchFocused, setSearchFocused] = useState(false);
  const [unfollowTarget, setUnfollowTarget] = useState<UnfollowTarget | null>(
    null,
  );

  // Style-tag chips from the loaded result set (open vocabulary).
  const tagOptions = useMemo(() => {
    const tags = new Set<string>();
    for (const post of explore.posts) {
      for (const tag of post.style_tags) tags.add(tag);
    }
    for (const tag of explore.tags) tags.add(tag);
    return [...tags].sort();
  }, [explore.posts, explore.tags]);

  const submit = (e: FormEvent) => {
    e.preventDefault();
    explore.submit(explore.query);
    setSearchFocused(false);
  };

  const showRecent =
    searchFocused && explore.recent.length > 0 && explore.query.length === 0;

  return (
    <div className="mx-auto flex max-w-4xl flex-col gap-4 px-4 py-6">
      <header className="flex flex-col gap-3">
        <h1 className="sr-only">Explore</h1>
        <div className="relative">
          <form role="search" onSubmit={submit}>
            <label htmlFor="explore-search" className="sr-only">
              Search designers, styles, tags
            </label>
            <Input
              id="explore-search"
              kind="search"
              placeholder="Search designers, styles, tags…"
              value={explore.query}
              onChange={(e) => explore.setQuery(e.target.value)}
              onFocus={() => setSearchFocused(true)}
              onBlur={() => setTimeout(() => setSearchFocused(false), 150)}
              autoComplete="off"
            />
          </form>
          {showRecent ? (
            <nav
              aria-label="Recent searches"
              className="absolute inset-x-0 top-full z-20 mt-1 rounded-card border border-border bg-bg-elev py-1 shadow-lg"
            >
              <ul>
                {explore.recent.map((term) => (
                  <li key={term}>
                    <button
                      type="button"
                      className="flex w-full px-3 py-2 text-left text-body text-text hover:bg-border/30"
                      onMouseDown={(e) => e.preventDefault()}
                      onClick={() => explore.submit(term)}
                    >
                      {term}
                    </button>
                  </li>
                ))}
              </ul>
            </nav>
          ) : null}
        </div>

        <ul aria-label="Filters" className="flex flex-wrap gap-2">
          {PRICE_BANDS.map((band) => (
            <li key={band.value}>
              <Chip
                label={band.label}
                kind={explore.priceBand === band.value ? "selected" : "default"}
                onClick={() =>
                  explore.setPriceBand(
                    explore.priceBand === band.value ? undefined : band.value,
                  )
                }
              />
            </li>
          ))}
          {TURNAROUNDS.map((t) => (
            <li key={t.value}>
              <Chip
                label={t.label}
                kind={
                  explore.maxTurnaround === t.value ? "selected" : "default"
                }
                onClick={() =>
                  explore.setMaxTurnaround(
                    explore.maxTurnaround === t.value ? undefined : t.value,
                  )
                }
              />
            </li>
          ))}
          <li>
            {/* Proximity ranking (designer location vs your profile
                location) — re-orders, never excludes (pages.md B2). */}
            <Chip
              label="Near me"
              kind={explore.nearMe ? "selected" : "default"}
              onClick={() => explore.setNearMe(!explore.nearMe)}
            />
          </li>
          {tagOptions.map((tag) => (
            <li key={tag}>
              <Chip
                label={tag}
                kind={explore.tags.includes(tag) ? "selected" : "default"}
                onClick={() => explore.toggleTag(tag)}
              />
            </li>
          ))}
        </ul>
      </header>

      {explore.submitted ? (
        <section aria-label="Designers" className="flex flex-col gap-1">
          <header className="flex items-baseline justify-between">
            <h2 className="text-body font-semibold text-text-2">Designers</h2>
            <button
              type="button"
              className="text-caption text-link"
              onClick={explore.clearSearch}
            >
              Clear search
            </button>
          </header>
          {explore.designersLoading ? (
            <Skeleton kind="line" />
          ) : explore.designers.length === 0 ? (
            <p className="text-caption text-text-2">
              No designers match “{explore.submitted}”.
            </p>
          ) : (
            <ul>
              {explore.designers.map((row) => (
                <li key={row.username}>
                  <UserRow
                    username={row.username}
                    avatarUrl={row.avatar_url}
                    meta={row.meta ?? undefined}
                    verified={row.verified}
                    trailing={row.viewer_follows ? "following" : "follow"}
                    onFollow={() =>
                      explore.toggleDesignerFollow(row).catch(() =>
                        showToast({
                          kind: "error",
                          message: `Couldn't follow ${row.username}`,
                          onRetry: () => void explore.toggleDesignerFollow(row),
                        }),
                      )
                    }
                    onFollowingTap={() =>
                      setUnfollowTarget({
                        username: row.username,
                        unfollow: () => explore.toggleDesignerFollow(row),
                      })
                    }
                    onOpen={() => router.push(`/dashboard/${row.username}`)}
                  />
                </li>
              ))}
            </ul>
          )}
        </section>
      ) : null}

      <section aria-label="Posts" className="flex flex-col gap-2">
        {explore.submitted ? (
          <h2 className="text-body font-semibold text-text-2">Posts</h2>
        ) : null}
        {explore.loading ? (
          <div aria-busy="true" className="grid grid-cols-3 gap-1">
            {Array.from({ length: 9 }, (_, i) => (
              <GridTile key={i} skeleton />
            ))}
          </div>
        ) : explore.posts.length === 0 ? (
          <EmptyState
            context="explore"
            line={
              explore.submitted
                ? `No posts match “${explore.submitted}”.`
                : undefined
            }
            ctaLabel={explore.submitted ? "Clear search" : undefined}
            onCta={explore.submitted ? explore.clearSearch : undefined}
          />
        ) : (
          <ul className="grid grid-cols-2 gap-1 md:grid-cols-3">
            {explore.posts.map((post) => (
              <li key={post.id}>
                <GridTile
                  src={post.media[0]?.url ?? ""}
                  alt={post.media[0]?.alt_text ?? ""}
                  likeCount={post.like_count}
                  commentCount={post.comment_count}
                  carousel={post.media.length > 1}
                  onClick={() => setOpenPostId(post.id)}
                />
              </li>
            ))}
          </ul>
        )}
      </section>

      <Sheet
        open={openPostId !== null}
        onOpenChange={(open) => {
          if (!open) {
            // Sync the grid tile's counts back on close — the modal's
            // usePost mutations don't touch this list (PR #102 review).
            if (openPostId) void explore.syncPost(openPostId);
            setOpenPostId(null);
          }
        }}
        title="Post"
        size="wide"
      >
        {openPostId ? (
          <PostDetailView
            key={openPostId}
            postId={openPostId}
            onRequest={(post) => setRequestPost(post)}
            onOverflow={(post) => setOptionsPost(post)}
          />
        ) : null}
      </Sheet>

      <RequestStepperSheet
        post={requestPost}
        onOpenChange={(open) => {
          if (!open) setRequestPost(null);
        }}
      />
      <PostOptionsSheet
        post={optionsPost}
        onOpenChange={(open) => {
          if (!open) setOptionsPost(null);
        }}
      />
      <UnfollowConfirmSheet
        target={unfollowTarget}
        onOpenChange={(open) => {
          if (!open) setUnfollowTarget(null);
        }}
      />
    </div>
  );
}
