"use client";

// ThemeToggle — the tri-state cycle control (theme contract, ratified
// 2026-07-20): light → dark → system → light, with a distinct icon per
// mode (sun / moon / monitor) and an aria-label announcing the ACTIVE
// mode plus the mode a press switches to. Rendered as an IconButton in
// the marketing nav; NavRail reuses the cycle/icon/label primitives with
// its own rail-item styling.
import { Monitor, Moon, Sun } from "lucide-react";
import type { LucideIcon } from "lucide-react";
import { IconButton } from "@/components/ui/IconButton";
import { useTheme, type ThemePreference } from "@/design/ThemeProvider";

/** light → dark → system → light. */
export const THEME_CYCLE: Record<ThemePreference, ThemePreference> = {
  light: "dark",
  dark: "system",
  system: "light",
};

export const THEME_ICONS: Record<ThemePreference, LucideIcon> = {
  light: Sun,
  dark: Moon,
  system: Monitor,
};

/** Accessible name: announces the active mode and the next one. */
export function themeToggleLabel(preference: ThemePreference): string {
  return `Theme: ${preference} — switch to ${THEME_CYCLE[preference]}`;
}

export function ThemeToggle({ size = "sm" }: { size?: "md" | "sm" }) {
  const { preference, setPreference } = useTheme();
  const Icon = THEME_ICONS[preference];
  return (
    <IconButton
      size={size}
      aria-label={themeToggleLabel(preference)}
      onClick={() => setPreference(THEME_CYCLE[preference])}
    >
      <Icon size={20} />
    </IconButton>
  );
}
