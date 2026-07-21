import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Emit a minimal, self-contained production server (.next/standalone/server.js)
  // for a small production Docker image.
  output: "standalone",
  // Demo imagery pipeline: the Firebase App Hosting adapter disables the
  // runtime image optimizer at deploy build time (it injects
  // `images.unoptimized = true` whenever no loader is configured), so
  // `/_next/image` does not exist on the live deploy. Instead, next/image
  // routes through the custom loader below onto pre-generated WebP variants
  // committed next to the originals (scripts/generate-demo-image-variants.mjs).
  // deviceSizes/imageSizes match the variant width buckets 1:1 so srcset
  // candidates and files on disk line up exactly.
  images: {
    loader: "custom",
    loaderFile: "./src/lib/demo-image-loader.ts",
    deviceSizes: [384, 640, 960],
    imageSizes: [128],
  },
};

export default nextConfig;
