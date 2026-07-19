"use client";

// B1 — Feed (pages.md): story rail (fresh outfits, MI-8) · 630px PostCard
// column with MI-1/2/3/4/9 + the request stepper CTA (MI-10) · right column
// (freshness MI-11 + suggestions MI-7) · skeleton / empty / caught-up
// states (MI-19, MI-6). Render-only over useFeed.
import { useEffect, useMemo, useRef, useState } from "react";
import Link from "next/link";
import type { Post } from "@/models";
import { useAuth } from "@/controllers/auth/AuthContext";
import { useFeed } from "@/controllers/use-feed";
import { Button } from "@/components/ui/Button";
import { CaughtUpDivider } from "@/components/ui/CaughtUpDivider";
import { EmptyState } from "@/components/ui/EmptyState";
import { PostCard } from "@/components/ui/PostCard";
import { Sheet } from "@/components/ui/Sheet";
import { StoryRailItem } from "@/components/ui/StoryRailItem";
import { UnfollowConfirmSheet, type UnfollowTarget } from "../UnfollowConfirmSheet";
import { PostDetailView } from "../post/PostDetailView";
import { FeedSidebar } from "./FeedSidebar";
import { PostOptionsSheet } from "./PostOptionsSheet";
import { RequestStepperSheet } from "./RequestStepperSheet";
import { maybeFirstSaveToast } from "../first-save";
import { useToasts } from "../toast-context";

const FRESH_MS = 48 * 60 * 60 * 1000; // story ring = outfits <48h (MI-8)

/** Story-rail projection — module fn so the clock read stays out of render
 * scope (same shape as models' freshnessOf). */
function storyDesignersOf(posts: Post[]): { username: string; fresh: boolean }[] {
  const now = Date.now();
  const byUsername = new Map<string, { username: string; fresh: boolean }>();
  for (const post of posts) {
    const existing = byUsername.get(post.designer.username);
    const fresh = now - new Date(post.created_at).getTime() < FRESH_MS;
    byUsername.set(post.designer.username, {
      username: post.designer.username,
      fresh: (existing?.fresh ?? false) || fresh,
    });
  }
  return [...byUsername.values()];
}

export function FeedView() {
  const feed = useFeed("feed");
  const { account } = useAuth();
  const { showToast } = useToasts();
  const [requestPost, setRequestPost] = useState<Post | null>(null);
  const [optionsPost, setOptionsPost] = useState<Post | null>(null);
  const [unfollowTarget, setUnfollowTarget] = useState<UnfollowTarget | null>(
    null,
  );
  const [flashPostId, setFlashPostId] = useState<string | null>(null);
  // Comments open the in-app post modal (B2's IG desktop pattern) — never a
  // full navigation out to the public /p permalink (P1 UX pass).
  const [openPostId, setOpenPostId] = useState<string | null>(null);

  // Story rail: followed designers, ring lit while they have <48h posts.
  const storyDesigners = useMemo(
    () => storyDesignersOf(feed.posts),
    [feed.posts],
  );

  // MI-6 infinite scroll: prefetch the next ranked page when the viewer is
  // 3 cards from the end — any of the last 3 cards entering the viewport
  // fires (robust to jump-scrolls, not just smooth ones). The observed set
  // moves as pages append; loadMore self-gates (cursor + in-flight ref).
  const listRef = useRef<HTMLUListElement | null>(null);
  const { loadMore, caughtUp } = feed;
  const postCount = feed.posts.length;
  useEffect(() => {
    const list = listRef.current;
    if (!list || caughtUp || postCount === 0) return;
    const cards = [...list.querySelectorAll(":scope > li")].slice(-3);
    if (cards.length === 0) return;
    const observer = new IntersectionObserver((entries) => {
      if (entries.some((entry) => entry.isIntersecting)) void loadMore();
    });
    for (const card of cards) observer.observe(card);
    return () => observer.disconnect();
  }, [loadMore, caughtUp, postCount]);

  const like = (post: Post) =>
    feed.toggleLike(post).catch(() =>
      showToast({
        kind: "error",
        message: "Couldn't like the post",
        onRetry: () => void feed.toggleLike(post),
      }),
    );
  const save = (post: Post) =>
    feed
      .toggleSave(post)
      .then(() => {
        // MI-3: post.saved is the pre-toggle value — false means this
        // toggle saved it.
        if (!post.saved) {
          maybeFirstSaveToast(showToast, account?.username ?? null);
        }
      })
      .catch(() =>
        showToast({
          kind: "error",
          message: "Couldn't save the post",
          onRetry: () => void feed.toggleSave(post),
        }),
      );

  const copyShareLink = async (post: Post) => {
    try {
      await navigator.clipboard.writeText(
        `${window.location.origin}/p/${post.id}`,
      );
    } catch {
      // clipboard unavailable
    }
    showToast({ kind: "neutral", message: "Link copied" });
    flash(post.id);
  };

  /** MI-9: post flashes a 1px gradient border 400ms on copy. */
  const flash = (postId: string) => {
    setFlashPostId(postId);
    setTimeout(() => setFlashPostId(null), 400);
  };

  return (
    <div className="mx-auto flex max-w-5xl justify-center gap-16 px-4 py-6">
      <div className="flex w-full max-w-[630px] flex-col">
        <h1 className="sr-only">Home feed</h1>

        {storyDesigners.length > 0 ? (
          <section aria-label="Fresh outfits" className="pb-4">
            <ul className="flex gap-4 overflow-x-auto pb-1">
              {storyDesigners.map((d) => (
                <li key={d.username}>
                  <Link href={`/dashboard/${d.username}`}>
                    <StoryRailItem
                      username={d.username}
                      state={d.fresh ? "unseen" : "seen"}
                    />
                  </Link>
                </li>
              ))}
            </ul>
          </section>
        ) : null}

        {feed.loading ? (
          <div aria-busy="true" className="flex flex-col gap-8">
            <PostCard skeleton />
            <PostCard skeleton />
          </div>
        ) : feed.error ? (
          <EmptyState
            context="feed"
            line="The feed couldn't load — try again."
            ctaLabel="Retry"
            onCta={() => void feed.reload()}
          />
        ) : feed.posts.length === 0 ? (
          <EmptyState
            context="feed"
            line="Follow designers to fill your feed"
            ctaLabel="Explore designers"
            onCta={() => window.location.assign("/dashboard/explore")}
          />
        ) : (
          <>
            <ul ref={listRef} className="flex flex-col gap-6" data-testid="feed-list">
              {feed.posts.map((post) => (
                <li
                  key={post.id}
                  className={
                    flashPostId === post.id
                      ? "rounded-card p-px [background:linear-gradient(45deg,var(--ap-accent-start),var(--ap-accent-end))]"
                      : "p-px"
                  }
                >
                  {/* PostCard is itself an <article> */}
                  <div className="bg-bg">
                    <PostCard
                      post={post}
                      onToggleLike={() => void like(post)}
                      onToggleSave={() => void save(post)}
                      onComment={() => setOpenPostId(post.id)}
                      onShare={() => void copyShareLink(post)}
                      onOverflow={() => setOptionsPost(post)}
                      onRequest={() => setRequestPost(post)}
                    />
                  </div>
                </li>
              ))}
            </ul>
            {feed.loadingMore ? (
              // MI-6: skeleton ×2 while the next page is in flight (MI-19
              // shimmer comes from the PostCard skeleton anatomy).
              <div
                aria-busy="true"
                className="flex flex-col gap-6 pt-6"
                data-testid="feed-loading-more"
              >
                <PostCard skeleton />
                <PostCard skeleton />
              </div>
            ) : feed.loadMoreError ? (
              // A cursor page failed: the observed cards are still
              // intersecting, so the MI-6 observer won't re-fire on its
              // own — offer an explicit retry (PR #103 review).
              <div
                role="status"
                className="flex items-center justify-center gap-3 py-6"
              >
                <span className="text-body text-text-2">
                  Couldn&apos;t load more posts.
                </span>
                <Button
                  kind="quiet"
                  data-testid="feed-load-more-retry"
                  onClick={() => void feed.loadMore()}
                >
                  Retry
                </Button>
              </div>
            ) : null}
            {feed.caughtUp ? <CaughtUpDivider className="py-6" /> : null}
          </>
        )}
      </div>

      <div className="hidden xl:block">
        <FeedSidebar
          onUnfollow={(username, unfollow) =>
            setUnfollowTarget({ username, unfollow })
          }
        />
      </div>

      <Sheet
        open={openPostId !== null}
        onOpenChange={(open) => {
          if (!open) {
            // Modal mutations live in PostDetailView's own usePost — sync
            // the rendered feed item back on close (PR #102 review).
            if (openPostId) void feed.syncPost(openPostId);
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
        onCopied={flash}
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
