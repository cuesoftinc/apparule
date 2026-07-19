// HomeFooter — design.md §8.2b: 3 link columns + legal + language
// (pages.md A10: product/docs/community columns · privacy (APP-005) ·
// terms · privacy.cuesoft.io clause link · language).
import clsx from "clsx";

export interface FooterColumn {
  heading: string;
  links: { label: string; href: string }[];
}

// Canvas footer content (Home instance 186:272, enriched landing).
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
      { label: "Quickstart", href: "https://docs.apparule.cuesoft.io" },
      { label: "API reference", href: "/docs/api" },
      { label: "GitBook", href: "https://docs.apparule.cuesoft.io" },
      { label: "Self-host guide", href: "https://docs.apparule.cuesoft.io/self-host" },
      { label: "Contributing", href: "https://github.com/cuesoftinc/apparule/blob/main/CONTRIBUTING.md" },
    ],
  },
  {
    heading: "Community",
    links: [
      { label: "GitHub", href: "https://github.com/cuesoftinc/apparule" },
      { label: "Discord", href: "https://discord.gg/cuesoft" },
      { label: "Roadmap", href: "https://github.com/cuesoftinc/apparule#roadmap" },
      { label: "Good first issues", href: "https://github.com/cuesoftinc/apparule/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22" },
      { label: "CueLABS", href: "https://cuesoft.io" },
    ],
  },
];

export interface HomeFooterProps {
  columns?: FooterColumn[];
  className?: string;
}

export function HomeFooter({ columns = DEFAULT_COLUMNS, className }: HomeFooterProps) {
  return (
    <footer className={clsx("border-t border-border px-6 py-12", className)}>
      <div className="mx-auto grid max-w-5xl grid-cols-2 gap-8 md:grid-cols-4">
        <div>
          <span className="bg-accent-gradient bg-clip-text text-title font-bold text-transparent">
            Apparule
          </span>
          <p className="mt-2 text-caption text-text-2">
            AI body measurement and made-to-measure fashion — open source,
            made for Lagos.
          </p>
        </div>
        {columns.map((column) => (
          <div key={column.heading}>
            <h3 className="text-body font-semibold text-text">{column.heading}</h3>
            <ul className="mt-3 flex flex-col gap-2">
              {column.links.map((link) => (
                <li key={link.label}>
                  <a href={link.href} className="text-body text-text-2 hover:text-text">
                    {link.label}
                  </a>
                </li>
              ))}
            </ul>
          </div>
        ))}
      </div>
      <div className="mx-auto mt-10 flex max-w-5xl flex-wrap items-center gap-x-6 gap-y-2 border-t border-border pt-6 text-caption text-text-2">
        <span>© {new Date().getFullYear()} Cuesoft · CueLABS</span>
        <a href="/privacy" className="hover:text-text">
          Privacy
        </a>
        <a href="/terms" className="hover:text-text">
          Terms
        </a>
        <a
          href="https://privacy.cuesoft.io"
          target="_blank"
          rel="noopener noreferrer"
          className="hover:text-text"
        >
          privacy.cuesoft.io
        </a>
        <label className="ml-auto flex items-center gap-2">
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
    </footer>
  );
}
