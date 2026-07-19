"use client";

// A1 nav wrapper — HomeNav instance wired to the controllers: the live
// star count (shared cached fetch seam with A7b, neutral "Star" fallback),
// `github_click` / `try_cloud_click`, the Try Cloud → /signin handoff, and
// the theme toggle.
import { useRouter } from "next/navigation";
import { Moon, Sun } from "lucide-react";
import { HomeNav } from "@/components/ui/HomeNav";
import { IconButton } from "@/components/ui/IconButton";
import { useTheme } from "@/design/ThemeProvider";
import { track } from "@/controllers/use-analytics";
import { useGithubStars } from "@/controllers/use-github-stars";

export function HomeNavBar() {
  const router = useRouter();
  const stars = useGithubStars();
  const { preference, setPreference } = useTheme();
  const nextTheme = preference === "dark" ? "light" : "dark";

  return (
    <HomeNav
      starCount={stars}
      onGithubClick={() => track("github_click", { section: "nav" })}
      onTryCloud={() => {
        track("try_cloud_click", { section: "nav" });
        router.push("/signin");
      }}
      trailing={
        <IconButton
          size="sm"
          aria-label={`Switch to ${nextTheme} theme`}
          onClick={() => setPreference(nextTheme)}
        >
          {preference === "dark" ? <Sun size={20} /> : <Moon size={20} />}
        </IconButton>
      }
    />
  );
}
