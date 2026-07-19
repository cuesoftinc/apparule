"use client";

// A1 nav wrapper — HomeNav instance wired to the controllers:
// `github_click` and the theme toggle (parity canon: the nav CTA is Sign
// in; the GitHub item is a plain text link — the live star badge is A7b's,
// DevelopersSection keeps the runtime fetch).
import { Moon, Sun } from "lucide-react";
import { HomeNav } from "@/components/ui/HomeNav";
import { IconButton } from "@/components/ui/IconButton";
import { useTheme } from "@/design/ThemeProvider";
import { track } from "@/controllers/use-analytics";

export function HomeNavBar() {
  const { preference, setPreference } = useTheme();
  const nextTheme = preference === "dark" ? "light" : "dark";

  return (
    <HomeNav
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
