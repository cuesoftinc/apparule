"use client";

// A1 nav wrapper — MarketingNav instance wired to the controllers: the live
// star count (shared cached fetch seam with A7b, neutral "Star" fallback),
// `github_click` / `try_cloud_click`, the Try Cloud → /signin handoff, and
// the theme toggle.
import { useRouter } from "next/navigation";
import { MarketingNav } from "@/components/ui/MarketingNav";
import { ThemeToggle } from "@/components/ui/ThemeToggle";
import { track } from "@/controllers/use-analytics";
import { useGithubStars } from "@/controllers/use-github-stars";

export function HomeNavBar() {
  const router = useRouter();
  const stars = useGithubStars();

  return (
    <MarketingNav
      starCount={stars}
      onGithubClick={() => track("github_click", { section: "nav" })}
      onTryCloud={() => {
        track("try_cloud_click", { section: "nav" });
        router.push("/signin");
      }}
      trailing={<ThemeToggle size="sm" />}
    />
  );
}
