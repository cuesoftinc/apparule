"use client";

// Suggested-designers controller (B1 right column): designers the viewer
// doesn't follow, with the optimistic MI-7 Follow morph. Following one
// keeps the row (morphed to "Following") so the unfollow confirm works.
import { useCallback, useEffect, useState } from "react";
import type { UserSummary } from "@/models";
import { designerRepo } from "@/models/repositories/designer-repo";
import { postsRepo } from "@/models/repositories/posts-repo";

export function useSuggestions() {
  const [rows, setRows] = useState<UserSummary[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    designerRepo.suggested().then(
      (page) => {
        if (cancelled) return;
        setRows(page.items);
        setLoading(false);
      },
      () => {
        if (!cancelled) setLoading(false);
      },
    );
    return () => {
      cancelled = true;
    };
  }, []);

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
