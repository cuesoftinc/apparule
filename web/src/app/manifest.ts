import type { MetadataRoute } from "next";

// Web app manifest (fleet SEO plumbing): installability identity served at
// /manifest.webmanifest, linked automatically from every route's <head>.
// Identity mirrors the home metadata (page.tsx); colors are the design.md §2
// light tokens — `bg` #ffffff, `accent-start` #e1306c (light-primary
// product; manifest colors can't bind CSS vars, so the hexes mirror
// src/design/tokens.css and must move with it). Icons are the committed
// set: the multi-size favicon.ico plus the 180×180 apple-icon.png.
export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "Apparule — Two photos. A perfect fit.",
    short_name: "Apparule",
    description:
      "Apparule turns two phone photos into a complete, private body-measurement profile. Commission Lagos designers who sew to your measurements — no size charts, no guesswork.",
    start_url: "/",
    display: "standalone",
    background_color: "#ffffff",
    theme_color: "#e1306c",
    icons: [
      {
        src: "/favicon.ico",
        sizes: "16x16 32x32 48x48 256x256",
        type: "image/x-icon",
      },
      {
        src: "/apple-icon.png",
        sizes: "180x180",
        type: "image/png",
      },
    ],
  };
}
