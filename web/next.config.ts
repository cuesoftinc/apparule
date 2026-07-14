import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Emit a minimal, self-contained production server (.next/standalone/server.js)
  // for a small production Docker image.
  output: "standalone",
};

export default nextConfig;
