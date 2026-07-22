"use client";

// B6 — Profiles ×2: designer (story-ring avatar, counts, Follow MI-7,
// Request CTA, bio, grid/saved tabs, self-only earnings link) and regular
// user (private-vault indicator, saved looks, order-history link).
// Followers/following counts open UserRow sheets. Render-only over
// usePublicProfile.
import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Lock } from "lucide-react";
import type { Post } from "@/models";
import { formatCount } from "@/lib/format";
import { useAuth } from "@/auth/AuthContext";
import {
  useFollowList,
  usePublicProfile,
} from "@/controllers/use-public-profile";
import { Avatar } from "@/components/ui/Avatar";
import { Button } from "@/components/ui/Button";
import { EmptyState } from "@/components/ui/EmptyState";
import { GridTile } from "@/components/ui/GridTile";
import { Sheet } from "@/components/ui/Sheet";
import { Skeleton } from "@/components/ui/Skeleton";
import { Tabs } from "@/components/ui/Tabs";
import { UserRow } from "@/components/ui/UserRow";
import { PostDetailView } from "../post/PostDetailView";
import { RequestStepperSheet } from "../feed/RequestStepperSheet";
import {
  UnfollowConfirmSheet,
  type UnfollowTarget,
} from "../UnfollowConfirmSheet";
import { useToasts } from "../toast-context";

function FollowListSheet({
  username,
  kind,
  open,
  onOpenChange,
  onUnfollow,
}: {
  username: string;
  kind: "followers" | "following";
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onUnfollow: (target: UnfollowTarget) => void;
}) {
  const list = useFollowList(username, kind, open);
  const router = useRouter();
  const { showToast } = useToasts();
  return (
    <Sheet
      open={open}
      onOpenChange={onOpenChange}
      title={kind === "followers" ? "Followers" : "Following"}
    >
      {list.loading ? (
        <Skeleton kind="line" />
      ) : list.rows.length === 0 ? (
        <p className="py-4 text-center text-body text-text-2">
          {kind === "followers" ? "No followers yet." : "Not following anyone."}
        </p>
      ) : (
        <ul data-testid={`${kind}-list`}>
          {list.rows.map((row) => (
            <li key={row.username}>
              <UserRow
                username={row.username}
                meta={row.meta ?? undefined}
                avatarUrl={row.avatar_url}
                verified={row.verified}
                trailing={
                  row.is_designer
                    ? row.viewer_follows
                      ? "following"
                      : "follow"
                    : "none"
                }
                onFollow={() =>
                  list.toggleFollow(row).catch(() =>
                    showToast({
                      kind: "error",
                      message: `Couldn't follow ${row.username}`,
                    }),
                  )
                }
                onFollowingTap={() =>
                  onUnfollow({
                    username: row.username,
                    unfollow: () => list.toggleFollow(row),
                  })
                }
                onOpen={() => router.push(`/dashboard/${row.username}`)}
              />
            </li>
          ))}
        </ul>
      )}
    </Sheet>
  );
}

export function ProfileView({ username }: { username: string }) {
  const { account } = useAuth();
  const router = useRouter();
  const { profile, posts, saved, loading, error, toggleFollow, syncPost } =
    usePublicProfile(username);
  const { showToast } = useToasts();
  const [tab, setTab] = useState<"first" | "second">("first");
  const [listSheet, setListSheet] = useState<null | "followers" | "following">(
    null,
  );
  const [openPostId, setOpenPostId] = useState<string | null>(null);
  const [requestPost, setRequestPost] = useState<Post | null>(null);
  const [unfollowTarget, setUnfollowTarget] = useState<UnfollowTarget | null>(
    null,
  );

  if (loading) {
    return (
      <div aria-busy="true" className="mx-auto max-w-4xl px-4 py-6">
        <Skeleton kind="card" />
      </div>
    );
  }
  if (error || !profile) {
    return (
      <div className="mx-auto max-w-4xl px-4 py-16 text-center">
        <h1 className="text-title font-bold text-text">Profile not found</h1>
        <p className="text-body text-text-2">
          @{username} doesn&apos;t exist (or isn&apos;t visible).
        </p>
      </div>
    );
  }

  // ---- regular-user profile ------------------------------------------------
  if (profile.kind === "user") {
    const self = profile.viewer_is_self;
    return (
      <div className="mx-auto flex max-w-4xl flex-col gap-6 px-4 py-6">
        <header className="flex items-center gap-6">
          {/* MI-11 [Decided 2026-07-20]: the freshness ring is a
              vault-header affordance — profile avatars (own included)
              render plain. */}
          <Avatar size={96} name={profile.account.display_name} />
          <div className="flex min-w-0 flex-col gap-1">
            <h1 className="text-title-lg font-bold text-text">
              {profile.account.username}
            </h1>
            <p className="text-body text-text-2">
              {profile.account.display_name}
            </p>
            <p className="flex items-center gap-1 text-caption text-text-2">
              <Lock size={12} aria-hidden /> Measurements are private — shared
              only inside a request.
            </p>
            {self ? (
              <p className="text-caption">
                <Link href="/dashboard/vault" className="text-link">
                  Open vault
                </Link>{" "}
                ·{" "}
                <Link href="/dashboard/orders" className="text-link">
                  Order history
                </Link>
              </p>
            ) : null}
          </div>
        </header>

        {self ? (
          <section aria-labelledby="saved-h" className="flex flex-col gap-2">
            <h2 id="saved-h" className="text-body font-semibold text-text-2">
              Saved looks
            </h2>
            {saved.length === 0 ? (
              <EmptyState
                context="explore"
                line="Save outfits you love and they'll collect here."
                ctaLabel="Explore outfits"
                onCta={() => router.push("/dashboard/explore")}
              />
            ) : (
              <ul
                className="grid grid-cols-2 gap-1 md:grid-cols-3"
                data-testid="saved-grid"
              >
                {saved.map((post) => (
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
        ) : null}

        <Sheet
          open={openPostId !== null}
          onOpenChange={(open) => {
            if (!open) {
              // Sync the grid tile(s) back on close — modal mutations live in
              // the modal's own usePost (PR #103 review).
              if (openPostId) void syncPost(openPostId);
              setOpenPostId(null);
            }
          }}
          title="Post"
          size="wide"
        >
          {openPostId ? (
            <PostDetailView
              postId={openPostId}
              onRequest={(post) => setRequestPost(post)}
            />
          ) : null}
        </Sheet>
        <RequestStepperSheet
          post={requestPost}
          onOpenChange={(open) => {
            if (!open) setRequestPost(null);
          }}
        />
      </div>
    );
  }

  // ---- designer profile ------------------------------------------------
  const d = profile.designer;
  const self = profile.viewer_is_self;
  const gridPosts = tab === "first" ? posts : saved;
  const isOwnAccount = account?.username === username;

  return (
    <div className="mx-auto flex max-w-4xl flex-col gap-6 px-4 py-6">
      <header className="flex items-start gap-6">
        {self ? (
          // MI-11 [Decided 2026-07-20]: own profile renders PLAIN (the
          // freshness ring is a vault-header affordance); others keep the
          // B6 story-ring construction (gradient).
          <Avatar
            size={96}
            name={d.display_name}
            src={d.avatar_url}
            verified={d.verified}
          />
        ) : (
          <Avatar
            size={96}
            name={d.display_name}
            src={d.avatar_url}
            ring="gradient"
            verified={d.verified}
          />
        )}
        <div className="flex min-w-0 flex-1 flex-col gap-2">
          <div className="flex flex-wrap items-center gap-3">
            <h1 className="text-title-lg font-bold text-text">{d.username}</h1>
            {!self ? (
              <>
                <Button
                  kind={profile.viewer_follows ? "quiet" : "gradient-primary"}
                  size="sm"
                  data-testid="profile-follow"
                  onClick={() => {
                    if (profile.viewer_follows) {
                      setUnfollowTarget({
                        username: d.username,
                        unfollow: toggleFollow,
                      });
                    } else {
                      void toggleFollow().catch(() =>
                        showToast({
                          kind: "error",
                          message: `Couldn't follow ${d.username}`,
                        }),
                      );
                    }
                  }}
                >
                  {profile.viewer_follows ? "Following" : "Follow"}
                </Button>
                {posts.length > 0 ? (
                  // Figma 182:969: Follow carries the gradient; Request is quiet.
                  <Button
                    kind="quiet"
                    size="sm"
                    onClick={() => setRequestPost(posts[0])}
                  >
                    Request an outfit
                  </Button>
                ) : null}
              </>
            ) : (
              <Link
                href="/dashboard/earnings"
                className="text-body text-link"
                data-testid="earnings-link"
              >
                Earnings
              </Link>
            )}
          </div>
          <ul className="flex flex-wrap gap-x-6 gap-y-1 text-body text-text">
            <li>
              <span className="tnum font-semibold">
                {formatCount(d.posts_count)}
              </span>{" "}
              posts
            </li>
            <li>
              <button
                type="button"
                className="hover:underline"
                onClick={() => setListSheet("followers")}
                data-testid="followers-count"
              >
                <span className="tnum font-semibold">
                  {formatCount(d.followers_count)}
                </span>{" "}
                followers
              </button>
            </li>
            <li>
              <button
                type="button"
                className="hover:underline"
                onClick={() => setListSheet("following")}
                data-testid="following-count"
              >
                <span className="tnum font-semibold">
                  {formatCount(d.following_count)}
                </span>{" "}
                following
              </button>
            </li>
          </ul>
          <p className="text-body text-text">{d.bio}</p>
          {d.location ? (
            <p className="text-caption text-text-2">
              {d.location.city}, {d.location.country}
            </p>
          ) : null}
        </div>
      </header>

      {isOwnAccount ? (
        <Tabs kind="icon" active={tab} onChange={setTab} />
      ) : null}

      <section aria-label={tab === "first" ? "Posts" : "Saved looks"}>
        {gridPosts.length === 0 ? (
          <EmptyState
            context="explore"
            line={
              tab === "first"
                ? self
                  ? "Publish your first outfit to open your storefront."
                  : "No posts yet."
                : "Save outfits you love and they'll collect here."
            }
            ctaLabel={tab === "first" && self ? "Create a post" : undefined}
            onCta={
              tab === "first" && self
                ? () => router.push("/dashboard/create")
                : undefined
            }
          />
        ) : (
          <ul
            className="grid grid-cols-2 gap-1 md:grid-cols-3"
            data-testid="profile-grid"
          >
            {gridPosts.map((post) => (
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

      <FollowListSheet
        username={username}
        kind="followers"
        open={listSheet === "followers"}
        onOpenChange={(open) => setListSheet(open ? "followers" : null)}
        onUnfollow={setUnfollowTarget}
      />
      <FollowListSheet
        username={username}
        kind="following"
        open={listSheet === "following"}
        onOpenChange={(open) => setListSheet(open ? "following" : null)}
        onUnfollow={setUnfollowTarget}
      />
      <Sheet
        open={openPostId !== null}
        onOpenChange={(open) => {
          if (!open) {
            // Sync the grid tile(s) back on close — modal mutations live in
            // the modal's own usePost (PR #103 review).
            if (openPostId) void syncPost(openPostId);
            setOpenPostId(null);
          }
        }}
        title="Post"
        size="wide"
      >
        {openPostId ? (
          <PostDetailView
            postId={openPostId}
            onRequest={(post) => setRequestPost(post)}
          />
        ) : null}
      </Sheet>
      <RequestStepperSheet
        post={requestPost}
        onOpenChange={(open) => {
          if (!open) setRequestPost(null);
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
