"use client";

// Composer controller (B5): media uploads (≤10 images, ≤10 MB, JPEG/PNG/
// WebP), drag-reorder, alt text with the "Outfit by {designer}" default,
// details form, publish → the post lands at the top of the feed.
import { useCallback, useState } from "react";
import { useRouter } from "next/navigation";
import { ApiError } from "@/lib/api";
import { postsRepo } from "@/models/repositories/posts-repo";

export interface ComposerMediaItem {
  /** Local identity for reorder/remove. */
  localId: string;
  /** Object URL for the preview tile. */
  previewUrl: string;
  /** Uploaded URL (mock object-storage stand-in); null while uploading. */
  url: string | null;
  altText: string;
  error: string | null;
}

export interface ComposerDetails {
  caption: string;
  styleTags: string[];
  /** null = "quote on request" (pages.md B5). */
  basePriceCents: number | null;
  turnaroundDays: number;
}

const MAX_ITEMS = 10;
const MAX_BYTES = 10 * 1024 * 1024;
const ALLOWED = ["image/jpeg", "image/png", "image/webp"];

export function useComposer() {
  const router = useRouter();
  const [media, setMedia] = useState<ComposerMediaItem[]>([]);
  const [details, setDetails] = useState<ComposerDetails>({
    caption: "",
    styleTags: [],
    basePriceCents: null,
    turnaroundDays: 14,
  });
  const [dropError, setDropError] = useState<string | null>(null);
  const [publishing, setPublishing] = useState(false);
  const [publishError, setPublishError] = useState<string | null>(null);

  const addFiles = useCallback(
    (files: File[]) => {
      setDropError(null);
      setMedia((prev) => {
        const room = MAX_ITEMS - prev.length;
        const accepted: ComposerMediaItem[] = [];
        for (const file of files.slice(0, room)) {
          if (!ALLOWED.includes(file.type)) {
            setDropError("Images must be JPEG, PNG, or WebP");
            continue;
          }
          if (file.size > MAX_BYTES) {
            setDropError("Images must be 10 MB or smaller");
            continue;
          }
          const item: ComposerMediaItem = {
            localId: crypto.randomUUID(),
            previewUrl: URL.createObjectURL(file),
            url: null,
            altText: "",
            error: null,
          };
          accepted.push(item);
          // Upload in the background; tile shows progress state until done.
          postsRepo.uploadMedia(file).then(
            (uploaded) => {
              setMedia((current) =>
                current.map((m) =>
                  m.localId === item.localId ? { ...m, url: uploaded.url } : m,
                ),
              );
            },
            () => {
              setMedia((current) =>
                current.map((m) =>
                  m.localId === item.localId
                    ? { ...m, error: "Upload failed" }
                    : m,
                ),
              );
            },
          );
        }
        if (files.length > room) {
          setDropError(`Posts carry at most ${MAX_ITEMS} images`);
        }
        return [...prev, ...accepted];
      });
    },
    [],
  );

  const removeItem = useCallback((localId: string) => {
    setMedia((prev) => prev.filter((m) => m.localId !== localId));
  }, []);

  const moveItem = useCallback((localId: string, direction: -1 | 1) => {
    setMedia((prev) => {
      const index = prev.findIndex((m) => m.localId === localId);
      const target = index + direction;
      if (index < 0 || target < 0 || target >= prev.length) return prev;
      const next = [...prev];
      [next[index], next[target]] = [next[target], next[index]];
      return next;
    });
  }, []);

  const setAltText = useCallback((localId: string, altText: string) => {
    setMedia((prev) =>
      prev.map((m) => (m.localId === localId ? { ...m, altText } : m)),
    );
  }, []);

  const uploading = media.some((m) => m.url === null && m.error === null);
  const canPublish =
    media.length > 0 &&
    !uploading &&
    media.every((m) => m.url !== null) &&
    details.caption.trim().length > 0 &&
    !publishing;

  const publish = useCallback(
    async (designerDisplayName: string) => {
      if (!canPublish) return null;
      setPublishing(true);
      setPublishError(null);
      try {
        const post = await postsRepo.create({
          caption: details.caption.trim(),
          style_tags: details.styleTags,
          base_price_cents: details.basePriceCents,
          turnaround_days: details.turnaroundDays,
          media: media.map((m) => ({
            url: m.url!,
            // Alt text required; default per design.md §5.
            alt_text:
              m.altText.trim() || `Outfit by ${designerDisplayName}`,
          })),
        });
        router.push("/dashboard");
        return post;
      } catch (e) {
        setPublishError(
          e instanceof ApiError ? e.message : "Publishing failed — try again.",
        );
        return null;
      } finally {
        setPublishing(false);
      }
    },
    [canPublish, details, media, router],
  );

  return {
    media,
    details,
    setDetails,
    addFiles,
    removeItem,
    moveItem,
    setAltText,
    dropError,
    uploading,
    canPublish,
    publish,
    publishing,
    publishError,
  };
}
