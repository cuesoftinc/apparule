// Custom next/image loader for the CC demo pool (public/demo/*.jpg).
//
// The deploy target (Firebase App Hosting Next.js adapter) turns the runtime
// image optimizer OFF — it injects `images.unoptimized = true` at build time
// unless a loader is configured — so `/_next/image` 404s in production and
// next/image would serve the raw 76–200 KB JPEGs at full intrinsic size.
// Instead, responsive WebP variants are pre-generated alongside the originals
// (scripts/generate-demo-image-variants.mjs, committed artifacts) and this
// loader maps each requested srcset width onto the nearest variant bucket.
// Works identically on App Hosting, the Docker standalone image, and dev.
//
// Non-demo srcs (blob: capture previews, absolute URLs) pass through
// untouched — the browser then treats every srcset candidate as the same URL.

/** Variant width buckets — keep in sync with scripts/generate-demo-image-variants.mjs. */
const VARIANT_WIDTHS = [128, 384, 640, 960];

export default function demoImageLoader({
  src,
  width,
}: {
  src: string;
  width: number;
  quality?: number;
}): string {
  const match = /^\/demo\/([\w.-]+)\.jpg$/.exec(src);
  if (!match) return src;
  const bucket =
    VARIANT_WIDTHS.find((w) => w >= width) ??
    VARIANT_WIDTHS[VARIANT_WIDTHS.length - 1];
  return `/demo/${match[1]}.w${bucket}.webp`;
}
