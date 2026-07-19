"use client";

// HomeNav — design.md §8.2b marketing kit: logo + links + GitHub star badge
// + Sign in + Try Cloud (gradient) · state top / stuck-blurred (blurs on
// scroll). Accuracy standard: the badge renders "Star" with no number until
// the live count arrives at runtime (fetched client-side by the page, A1).
import { useEffect, useState, type ReactNode } from "react";
import clsx from "clsx";
import Link from "next/link";
import { Star } from "lucide-react";
import { Button } from "./Button";
import { GitHubMark } from "@/components/icons/GitHubMark";

export interface HomeNavLink {
  label: string;
  href: string;
}

export interface HomeNavProps {
  links?: HomeNavLink[];
  /** Live star count (fetched at runtime); null renders the neutral badge. */
  starCount?: number | null;
  githubHref?: string;
  onTryCloud?: () => void;
  /** Analytics seam: `github_click` fires here (pages.md A1). */
  onGithubClick?: () => void;
  /**
   * Trailing slot before Sign in — the page mounts the theme toggle here
   * (W2 adaptation: light/dark QA + the §8.4 marketing journey need a
   * public-surface toggle; the Figma nav master carries no toggle).
   */
  trailing?: ReactNode;
  className?: string;
}

const DEFAULT_LINKS: HomeNavLink[] = [
  { label: "Product", href: "#product" },
  { label: "Docs", href: "https://docs.apparule.cuesoft.io" },
  { label: "Community", href: "#community" },
];

export function HomeNav({
  links = DEFAULT_LINKS,
  starCount = null,
  githubHref = "https://github.com/cuesoftinc/apparule",
  onTryCloud,
  onGithubClick,
  trailing,
  className,
}: HomeNavProps) {
  const [stuck, setStuck] = useState(false);

  useEffect(() => {
    const onScroll = () => setStuck(window.scrollY > 8);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  return (
    <nav
      data-state={stuck ? "stuck-blurred" : "top"}
      aria-label="Home"
      className={clsx(
        "sticky top-0 z-10 flex h-16 items-center gap-6 px-6 transition-colors duration-200 ease-standard",
        stuck
          ? "border-b border-border bg-bg/80 backdrop-blur-md"
          : "bg-transparent",
        "motion-reduce:transition-none",
        className,
      )}
    >
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
      </div>
      <div className="ml-auto flex items-center gap-3">
        <a
          href={githubHref}
          target="_blank"
          rel="noopener noreferrer"
          data-testid="star-badge"
          onClick={onGithubClick}
          // hidden <sm: 375-width adaptation (Figma nav is 1440-only)
          className="hidden h-9 items-center gap-2 rounded-pill border border-border px-3 text-body font-semibold text-text hover:bg-border/30 sm:flex"
        >
          <GitHubMark size={16} />
          <Star size={14} className="text-warn" />
          <span className="tnum">
            {starCount === null ? "Star" : starCount.toLocaleString("en-NG")}
          </span>
        </a>
        {trailing}
        <Link
          href="/signin"
          className="whitespace-nowrap text-body font-semibold text-text hover:text-text-2"
        >
          Sign in
        </Link>
        <Button kind="gradient-primary" size="sm" onClick={onTryCloud}>
          Try Cloud
        </Button>
      </div>
    </nav>
  );
}
