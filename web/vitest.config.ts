import react from "@vitejs/plugin-react";
import tsconfigPaths from "vite-tsconfig-paths";
import { defineConfig } from "vitest/config";

/**
 * Vitest — the single unit/integration runner; tests co-locate under src/**.
 * jsdom by default (components); server-side suites pin
 * `@vitest-environment node` per file. `globals` enables RTL auto-cleanup.
 */
export default defineConfig({
  plugins: [react(), tsconfigPaths()],
  test: {
    environment: "jsdom",
    // Repo-specific: localStorage needs a non-opaque origin — several
    // suites exercise absolute-URL reads.
    environmentOptions: { jsdom: { url: "http://localhost:3000" } },
    globals: true,
    setupFiles: ["./vitest.setup.ts"],
    include: ["src/**/*.test.{ts,tsx}"],
    exclude: ["node_modules/**", "src/legacy/**", "e2e/**"],
    // Repo-specific: no NEXT_PUBLIC_TEST_MODE here — suites assert the
    // TEST_MODE-unset defaults (analytics transport, GitHub-stars repo).
  },
});
