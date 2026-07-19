// GitHub repository metadata — the home page's live star count
// (pages.md A1/A7b: "the live count is populated at runtime; static designs
// render the badge with no number"). This is a third-party surface, not
// api/common, but network access still lives in the models layer (MVC rule).
//
// Graceful degradation: any failure resolves to null and the badge keeps
// its neutral "Star" label (accuracy standard — never an invented count).
// TEST_MODE skips the network entirely so CI is deterministic and offline.
import { env } from "@/config/env";

export const GITHUB_REPO = "cuesoftinc/apparule";
export const GITHUB_REPO_URL = `https://github.com/${GITHUB_REPO}`;

export const githubRepo = {
  /** Star count for the badge; null → neutral "Star" fallback. */
  async stars(repo: string = GITHUB_REPO): Promise<number | null> {
    if (env.testMode) return null;
    try {
      const res = await fetch(`https://api.github.com/repos/${repo}`, {
        headers: { Accept: "application/vnd.github+json" },
      });
      if (!res.ok) return null;
      const body = (await res.json()) as { stargazers_count?: unknown };
      return typeof body.stargazers_count === "number"
        ? body.stargazers_count
        : null;
    } catch {
      return null;
    }
  },
};
