"use client";

// A1 nav wrapper — HomeNav instance wired to the controllers: live star
// count (count-up once, neutral "Star" fallback), `github_click`, and the
// theme toggle (parity canon: the nav CTA is Sign in — a plain /signin
// link; try_cloud_click keeps firing from the hero/A9c/comparison CTAs).
import { Moon, Sun } from "lucide-react";
import { HomeNav } from "@/components/ui/HomeNav";
import { IconButton } from "@/components/ui/IconButton";
import { useTheme } from "@/design/ThemeProvider";
import { track } from "@/controllers/use-analytics";
import { useGithubStars } from "@/controllers/use-github-stars";

export function HomeNavBar() {
  const stars = useGithubStars();
  const { preference, setPreference } = useTheme();
  const nextTheme = preference === "dark" ? "light" : "dark";

  return (
    <HomeNav
      starCount={stars}
      onGithubClick={() => track("github_click", { section: "nav" })}
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
