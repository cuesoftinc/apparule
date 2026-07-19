"use client";

// HomeNav — design.md §8.2b marketing kit, links per the org "Marketing
// nav, footer & theme parity canon" (SKILL.md, 2026-07-19, star-badge
// adjudication): four PLAIN text links — Features · For designers · Docs ·
// GitHub — + theme-toggle slot + the "Sign in" gradient CTA · state top /
// stuck-blurred (blurs on scroll). The live star badge lives on A7b only
// (DevelopersSection); a nav badge on one product is cross-repo drift.
// Below md the four links collapse into a hamburger disclosure whose panel
// carries the same links + the theme toggle + Sign in (canon extension,
// 2026-07-19 — previously the links simply vanished on mobile).
import { useEffect, useState, type ReactNode } from "react";
import clsx from "clsx";
import Link from "next/link";
import { Menu, X } from "lucide-react";

export interface HomeNavLink {
  label: string;
  href: string;
}

export interface HomeNavProps {
  links?: HomeNavLink[];
  githubHref?: string;
  /** Analytics seam: `github_click` fires here (pages.md A1). */
  onGithubClick?: () => void;
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

export function HomeNav({
  links = DEFAULT_LINKS,
  githubHref = "https://github.com/cuesoftinc/apparule",
  onGithubClick,
  trailing,
  className,
}: HomeNavProps) {
  const [stuck, setStuck] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);

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
          {/* canon link 4/4 — plain text like the rest (adjudicated) */}
          <a
            href={githubHref}
            target="_blank"
            rel="noopener noreferrer"
            data-testid="nav-github"
            onClick={onGithubClick}
            className="text-body text-text-2 hover:text-text"
          >
            GitHub
          </a>
        </div>
        <div className="ml-auto hidden items-center gap-3 md:flex">
          {trailing}
          {/* Parity canon: one nav CTA — Sign in, on apparule's gradient */}
          <Link
            href="/signin"
            className="inline-flex h-9 items-center justify-center whitespace-nowrap rounded-card bg-accent-gradient px-3 text-caption font-semibold text-on-accent"
          >
            Sign in
          </Link>
        </div>
        {/* <md: the canon links collapse into a hamburger disclosure */}
        <button
          type="button"
          aria-label={menuOpen ? "Close menu" : "Open menu"}
          aria-expanded={menuOpen}
          aria-controls="home-nav-menu"
          data-testid="nav-menu-button"
          onClick={() => setMenuOpen((open) => !open)}
          className="ml-auto grid size-11 place-items-center rounded-card text-text md:hidden"
        >
          {menuOpen ? <X size={24} /> : <Menu size={24} />}
        </button>
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
          <a
            href={githubHref}
            target="_blank"
            rel="noopener noreferrer"
            onClick={() => {
              onGithubClick?.();
              setMenuOpen(false);
            }}
            className="flex h-11 items-center text-body text-text-2 hover:text-text"
          >
            GitHub
          </a>
          <div className="mt-2 flex items-center justify-between border-t border-border pt-3">
            {trailing}
            <Link
              href="/signin"
              onClick={() => setMenuOpen(false)}
              className="inline-flex h-9 items-center justify-center whitespace-nowrap rounded-card bg-accent-gradient px-3 text-caption font-semibold text-on-accent"
            >
              Sign in
            </Link>
          </div>
        </div>
      ) : null}
    </nav>
  );
}
