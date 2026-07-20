// MarketingFooter — design.md §8.2b marketing kit, laid out to the org
// "Marketing nav, footer & theme parity canon" (SKILL.md, ratified
// 2026-07-19): brand block + 4 link columns (Product · Docs · Community ·
// Legal) + legal bar (verbatim © line · security policy · language).
// pages.md A10's privacy/terms/clause links live in the Legal column now.
import clsx from "clsx";
import { ShieldCheck } from "lucide-react";

export interface FooterColumn {
  heading: string;
  links: { label: string; href: string }[];
}

// Canonical link set — URLs are the ratified, verified-200 targets.
const DEFAULT_COLUMNS: FooterColumn[] = [
  {
    heading: "Product",
    links: [
      { label: "Features", href: "/#product" },
      { label: "Try Cloud", href: "/signin" },
      { label: "Self Host", href: "/#self-host" },
      { label: "For designers", href: "/#designers" },
    ],
  },
  {
    heading: "Docs",
    links: [
      { label: "Docs", href: "https://cuesoft.gitbook.io/apparule" },
      {
        label: "Quickstart",
        href: "https://cuesoft.gitbook.io/apparule/setup",
      },
      // In-product Scalar reference (F0-8) — renders docs/api/openapi.yaml.
      { label: "API reference", href: "/docs/api" },
      {
        label: "Self-host guide",
        href: "https://cuesoft.gitbook.io/apparule/system/deployment",
      },
    ],
  },
  {
    heading: "Community",
    links: [
      { label: "GitHub", href: "https://github.com/cuesoftinc/apparule" },
      { label: "Discord", href: "https://discord.gg/CDfZxxrxbb" },
      {
        label: "Roadmap",
        href: "https://cuesoft.gitbook.io/apparule/product/roadmap",
      },
      { label: "CueLABS™", href: "https://cuelabs.cuesoft.io" },
    ],
  },
  {
    heading: "Legal",
    links: [
      { label: "Privacy", href: "https://privacy.cuesoft.io" },
      { label: "Terms", href: "https://terms.cuesoft.io" },
      { label: "Status", href: "https://status.cuesoft.io" },
    ],
  },
];

export interface MarketingFooterProps {
  columns?: FooterColumn[];
  className?: string;
}

export function MarketingFooter({
  columns = DEFAULT_COLUMNS,
  className,
}: MarketingFooterProps) {
  return (
    <footer className={clsx("border-t border-border px-6 py-12", className)}>
      {/* Canonical 1080 content column (design.md container canon) —
          max-w-5xl (1024) drifted off the section grid (W2.1 live-QA). */}
      <div className="mx-auto grid max-w-[1080px] grid-cols-2 gap-8 md:grid-cols-5">
        <div className="col-span-2 md:col-span-1">
          <span className="bg-accent-gradient bg-clip-text text-title font-bold text-transparent">
            Apparule
          </span>
          <p className="mt-2 text-caption text-text-2">
            AI body measurement and made-to-measure fashion — open-source, made
            for Lagos.
          </p>
        </div>
        {columns.map((column) => (
          <div key={column.heading}>
            <h3 className="text-body font-semibold text-text">
              {column.heading}
            </h3>
            <ul className="mt-3 flex flex-col gap-2">
              {column.links.map((link) => (
                <li key={link.label}>
                  <a
                    href={link.href}
                    className="text-body text-text-2 hover:text-text"
                  >
                    {link.label}
                  </a>
                </li>
              ))}
            </ul>
          </div>
        ))}
      </div>
      {/* Legal bar layout (parity canon; Figma master 98:1248): verbatim
          © line left · [Security policy · English ▾] cluster right
          (Security affordance 328:8010 sits with the language selector).
          flex-wrap keeps the cluster flowing under the © line at 390. */}
      <div className="mx-auto mt-10 flex max-w-[1080px] flex-wrap items-center justify-between gap-x-6 gap-y-2 border-t border-border pt-6 text-caption text-text-2">
        {/* Verbatim legal line (parity canon): © Cuesoft Inc. 2026.
            Apparule. CueLABS™ Division. MIT License. */}
        <span>
          ©{" "}
          <a
            href="https://cuesoft.io"
            target="_blank"
            rel="noopener noreferrer"
            className="hover:text-text"
          >
            Cuesoft Inc.
          </a>{" "}
          2026. Apparule.{" "}
          <a
            href="https://cuelabs.cuesoft.io"
            target="_blank"
            rel="noopener noreferrer"
            className="hover:text-text"
          >
            CueLABS™ Division
          </a>
          .{" "}
          <a
            href="https://github.com/cuesoftinc/apparule/blob/main/LICENSE"
            target="_blank"
            rel="noopener noreferrer"
            className="hover:text-text"
          >
            MIT License
          </a>
          .
        </span>
        <div
          data-testid="legal-bar-utilities"
          className="flex flex-wrap items-center gap-x-6 gap-y-2"
        >
          <a
            href="https://github.com/cuesoftinc/apparule/blob/main/SECURITY.md"
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-1 hover:text-text"
          >
            <ShieldCheck size={14} aria-hidden />
            Security policy
          </a>
          <label className="flex items-center gap-2">
            <span className="sr-only">Language</span>
            <select
              aria-label="Language"
              defaultValue="en"
              className="rounded-card border border-border bg-bg-elev px-2 py-1 text-caption text-text"
            >
              <option value="en">English</option>
            </select>
          </label>
        </div>
      </div>
    </footer>
  );
}
