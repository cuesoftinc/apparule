"use client";

// Public-profile controller (B6): profile header (designer or regular
// user), posts/saved grids, follow morph (MI-7 — optimistic), and the
// followers/following sheets (lazy-loaded UserRow lists).
import { useCallback, useEffect, useState } from "react";
import type { Post, PublicProfile, UserSummary } from "@/models";
import { postsRepo } from "@/models/repositories/posts-repo";
import { profilesRepo } from "@/models/repositories/profiles-repo";

export function usePublicProfile(username: string) {
  const [profile, setProfile] = useState<PublicProfile | null>(null);
  const [posts, setPosts] = useState<Post[]>([]);
  const [saved, setSaved] = useState<Post[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Views mount one instance per username (page keys by the route param) —
  // loading starts true; state settles only in promise callbacks.
  useEffect(() => {
    let cancelled = false;
    profilesRepo.get(username).then(
      async (fetched) => {
        if (cancelled) return;
        setProfile(fetched);
        try {
          if (fetched.kind === "designer") {
            const page = await profilesRepo.posts(username);
            if (!cancelled) setPosts(page.items);
          }
          if (fetched.viewer_is_self) {
            const savedPage = await profilesRepo.saved();
            if (!cancelled) setSaved(savedPage.items);
          }
        } finally {
          if (!cancelled) setLoading(false);
        }
      },
      (e: unknown) => {
        if (cancelled) return;
        setError(e instanceof Error ? e.message : "Profile not found");
        setLoading(false);
      },
    );
    return () => {
      cancelled = true;
    };
  }, [username]);

  /** Optimistic follow/unfollow with follower-count tick (MI-7 + MI-18). */
  const toggleFollow = useCallback(async () => {
    if (!profile || profile.kind !== "designer") return;
    const was = profile;
    const on = !was.viewer_follows;
    setProfile({
      ...was,
      viewer_follows: on,
      designer: {
        ...was.designer,
        followers_count: was.designer.followers_count + (on ? 1 : -1),
      },
    });
    try {
      await (on
        ? postsRepo.follow(username)
        : postsRepo.unfollow(username));
    } catch {
      setProfile(was);
      throw new Error("follow_failed");
    }
  }, [profile, username]);

  /** Refresh the saved grid (after unsave from the grid, etc.). */
  const reloadSaved = useCallback(async () => {
    const page = await profilesRepo.saved();
    setSaved(page.items);
  }, []);

  return { profile, posts, saved, loading, error, toggleFollow, reloadSaved };
}

/** Followers/following sheet lists — fetched when the sheet opens. */
export function useFollowList(
  username: string,
  kind: "followers" | "following",
  open: boolean,
) {
  const [rows, setRows] = useState<UserSummary[]>([]);
  const [loaded, setLoaded] = useState(false);
  // Derived, not stateful — keeps setState out of the effect body.
  const loading = open && !loaded;

  useEffect(() => {
    if (!open || loaded) return;
    let cancelled = false;
    const request =
      kind === "followers"
        ? profilesRepo.followers(username)
        : profilesRepo.following(username);
    request.then(
      (page) => {
        if (cancelled) return;
        setRows(page.items);
        setLoaded(true);
      },
      () => {
        if (!cancelled) setLoaded(true);
      },
    );
    return () => {
      cancelled = true;
    };
  }, [open, loaded, kind, username]);

  /** Optimistic MI-7 morph on a row. */
  const toggleFollow = useCallback(async (row: UserSummary) => {
    const on = !row.viewer_follows;
    setRows((prev) =>
      prev.map((r) =>
        r.username === row.username ? { ...r, viewer_follows: on } : r,
      ),
    );
    try {
      await (on
        ? postsRepo.follow(row.username)
        : postsRepo.unfollow(row.username));
    } catch {
      setRows((prev) =>
        prev.map((r) =>
          r.username === row.username
            ? { ...r, viewer_follows: row.viewer_follows }
            : r,
        ),
      );
      throw new Error("follow_failed");
    }
  }, []);

  return { rows, loading, toggleFollow };
}
