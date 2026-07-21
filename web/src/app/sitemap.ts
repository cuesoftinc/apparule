import type { MetadataRoute } from "next";

/**
 * Public marketing surface only (SEO plumbing, fleet canon): the home page
 * and the public Scalar API reference. Auth (/signin) and app
 * (/dashboard/*) routes stay out by design; /p/* permalinks are runtime
 * content, not build-time marketing routes.
 */
const BASE = "https://apparule.cuesoft.io";

export default function sitemap(): MetadataRoute.Sitemap {
  return [
    { url: BASE, changeFrequency: "weekly", priority: 1 },
    { url: `${BASE}/docs/api`, changeFrequency: "weekly", priority: 0.5 },
  ];
}
