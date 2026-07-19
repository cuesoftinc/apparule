"use client";

// HomeNav — design.md §8.2b marketing kit, per the org "Marketing nav,
// footer & theme parity canon" (SKILL.md, revised 2026-07-19): four links
// — Features · For designers · Docs · GitHub, with GitHub rendered as the
// compact star badge (star glyph + "Star" + the live count from the shared
// cached fetch seam; TEST_MODE/failure keep the neutral "Star" label,
// never a hardcoded count) — + theme-toggle slot + the "Sign in" text link
// + the "Try Cloud" gradient primary CTA (→ /signin) · state top /
// stuck-blurred (blurs on scroll). Below md the links collapse into a
// hamburger disclosure; the bar keeps the Try Cloud CTA beside the
// hamburger and the panel carries the links + ThemeToggle + Sign in
// [Revised 2026-07-19 canon].
import { useEffect, useState, type ReactNode } from "react";
import clsx from "clsx";
import Link from "next/link";
import { Menu, Star, X } from "lucide-react";
import { Button } from "./Button";
import { GitHubMark } from "@/components/icons/GitHubMark";

export interface HomeNavLink {
  label: string;
  href: string;
}

export interface HomeNavProps {
  links?: HomeNavLink[];
  githubHref?: string;
  /** Live star count (shared cached fetch); null keeps the neutral badge. */
  starCount?: number | null;
  /** Analytics seam: `github_click` fires here (pages.md A1). */
  onGithubClick?: () => void;
  /** Try Cloud handoff (→ /signin) — `try_cloud_click` fires here. */
  onTryCloud?: () => void;
  /**
   * Trailing slot before Sign in — the page mounts the theme toggle here
   * (W2 adaptation: light/dark QA + the §8.4 marketing journey need a
   * public-surface toggle; the Figma nav master carries no toggle). Below
   * md the slot renders inside the disclosure panel instead.
   */
  trailing?: ReactNode;
  className?: string;
}

const DEFAULT_LINKS: HomeNavLink[] = [
  { label: "Features", href: "#product" },
  { label: "For designers", href: "#designers" },
  { label: "Docs", href: "https://cuesoft.gitbook.io/apparule" },
];

// Shared badge contents (icon + star glyph + live count) — desktop wraps
// this in the compact pill, the mobile panel wraps it in a plain 44px row;
// both read starCount off the same useGithubStars seam, neutral "Star" in
// TEST_MODE/failure (accuracy standard: no invented counts).
function StarBadgeLabel({ starCount }: { starCount: number | null }) {
  return (
    <>
      <GitHubMark size={14} />
      <Star size={12} className="text-warn" />
      <span className="tnum">
        {starCount === null ? "Star" : starCount.toLocaleString("en-NG")}
      </span>
    </>
  );
}

// Derived from githubHref (review fix, PR #99): a caller-supplied override
// must not leave the badge's accessible name announcing "cuesoftinc/apparule"
// for a different repository — falls back to the generic "GitHub" if the
// href doesn't parse as `github.com/<owner>/<repo>`.
function githubRepoSlug(href: string): string {
  try {
    const { hostname, pathname } = new URL(href);
    const slug = pathname.replace(/^\/+|\/+$/g, "");
    return hostname === "github.com" && slug ? slug : "GitHub";
  } catch {
    return "GitHub";
  }
}

export function HomeNav({
  links = DEFAULT_LINKS,
  githubHref = "https://github.com/cuesoftinc/apparule",
  starCount = null,
  onGithubClick,
  onTryCloud,
  trailing,
  className,
}: HomeNavProps) {
  const [stuck, setStuck] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);
  const githubAriaLabel = `Star ${githubRepoSlug(githubHref)} on GitHub`;

  useEffect(() => {
    const onScroll = () => setStuck(window.scrollY > 8);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  // Disclosure a11y: Escape closes and the trigger reflects aria-expanded.
  useEffect(() => {
    if (!menuOpen) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") setMenuOpen(false);
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [menuOpen]);

  return (
    <nav
      data-state={stuck ? "stuck-blurred" : "top"}
      aria-label="Home"
      className={clsx(
        "sticky top-0 z-10 h-16 px-6 transition-colors duration-200 ease-standard",
        stuck || menuOpen
          ? "border-b border-border bg-bg/80 backdrop-blur-md"
          : "bg-transparent",
        "motion-reduce:transition-none",
        className,
      )}
    >
      {/* Bar spans full-bleed; content sits on the canonical 1080 content
          column (design.md container canon — x 180–1260 at 1440) so the
          logo and CTAs line up with every section edge (W2.1 live-QA). */}
      <div className="mx-auto flex h-full w-full max-w-[1080px] items-center gap-6">
        <Link href="/" className="bg-accent-gradient bg-clip-text text-title font-bold text-transparent">
          Apparule
        </Link>
        <div className="hidden items-center gap-5 md:flex">
          {links.map((link) => (
            <a
              key={link.label}
              href={link.href}
              className="text-body text-text-2 hover:text-text"
            >
              {link.label}
            </a>
          ))}
          {/* link 4/4 — GitHub as the compact star badge (canon revision) */}
          <a
            href={githubHref}
            target="_blank"
            rel="noopener noreferrer"
            data-testid="star-badge"
            aria-label={githubAriaLabel}
            onClick={onGithubClick}
            className="flex h-9 items-center gap-2 rounded-pill border border-border px-3 text-caption font-semibold text-text hover:bg-border/30"
          >
            <StarBadgeLabel starCount={starCount} />
          </a>
        </div>
        <div className="ml-auto hidden items-center gap-3 md:flex">
          {trailing}
          <Link
            href="/signin"
            className="whitespace-nowrap text-body font-semibold text-text hover:text-text-2"
          >
            Sign in
          </Link>
          {/* the one primary CTA — Try Cloud on apparule's gradient */}
          <Button kind="gradient-primary" size="sm" onClick={onTryCloud}>
            Try Cloud
          </Button>
        </div>
        {/* <md [Revised 2026-07-19 canon]: the bar keeps the Try Cloud CTA
            beside the hamburger; the text links collapse into the
            disclosure panel. */}
        <div className="ml-auto flex items-center gap-2 md:hidden">
          <Button kind="gradient-primary" size="sm" onClick={onTryCloud}>
            Try Cloud
          </Button>
          <button
            type="button"
            aria-label={menuOpen ? "Close menu" : "Open menu"}
            aria-expanded={menuOpen}
            aria-controls="home-nav-menu"
            data-testid="nav-menu-button"
            onClick={() => setMenuOpen((open) => !open)}
            className="grid size-11 place-items-center rounded-card text-text"
          >
            {menuOpen ? <X size={24} /> : <Menu size={24} />}
          </button>
        </div>
      </div>
      {menuOpen ? (
        <div
          id="home-nav-menu"
          data-testid="nav-menu-panel"
          className={clsx(
            "absolute inset-x-0 top-16 flex flex-col gap-1 border-b border-border bg-bg px-6 pb-4 pt-2 shadow-[0_8px_16px_rgba(0,0,0,0.08)] md:hidden",
            "animate-[nav-menu-in_200ms_var(--ap-ease-standard)] motion-reduce:animate-none",
          )}
        >
          {links.map((link) => (
            <a
              key={link.label}
              href={link.href}
              onClick={() => setMenuOpen(false)}
              className="flex h-11 items-center text-body text-text-2 hover:text-text"
            >
              {link.label}
            </a>
          ))}
          {/* panel GitHub item — the same compact star badge as desktop
              (Codex P2: this used to render a plain "GitHub" text link and
              never read starCount). */}
          <a
            href={githubHref}
            target="_blank"
            rel="noopener noreferrer"
            aria-label={githubAriaLabel}
            onClick={() => {
              onGithubClick?.();
              setMenuOpen(false);
            }}
            className="flex h-11 items-center gap-2 text-body text-text-2 hover:text-text"
          >
            <StarBadgeLabel starCount={starCount} />
          </a>
          {/* Try Cloud already sits on the bar (canon) — the panel carries
              only the links + ThemeToggle + Sign in, no duplicate CTA. */}
          <div className="mt-2 flex items-center justify-between gap-3 border-t border-border pt-3">
            {trailing}
            <Link
              href="/signin"
              onClick={() => setMenuOpen(false)}
              className="whitespace-nowrap text-body font-semibold text-text hover:text-text-2"
            >
              Sign in
            </Link>
          </div>
        </div>
      ) : null}
    </nav>
  );
}
