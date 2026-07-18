"use client";

// NavRail + NavRailItem — design.md §8.2b (as built: decomposed into the
// rail + child item set): width collapsed 72 / expanded 244 (≥1264px) ·
// item ×7 (Home / Explore / Create / Orders / Vault / Profile / Settings) ·
// state default / active / hover · footer slot: theme toggle + support link.
import clsx from "clsx";
import Link from "next/link";
import {
  Home,
  Info,
  Moon,
  Package,
  Plus,
  Ruler,
  Search,
  Settings,
  Sun,
  User,
  type LucideIcon,
} from "lucide-react";
import { useTheme } from "@/design/ThemeProvider";

export interface NavRailItemSpec {
  key: string;
  label: string;
  href: string;
  icon: LucideIcon;
  /** Orders badge (MI-16): unread count, clears on tab visit. */
  badge?: number;
}

// Figma master (84:1046): explore = search glyph, create = plain plus.
export const DEFAULT_NAV_ITEMS: NavRailItemSpec[] = [
  { key: "home", label: "Home", href: "/dashboard", icon: Home },
  { key: "explore", label: "Explore", href: "/dashboard/explore", icon: Search },
  { key: "create", label: "Create", href: "/dashboard/create", icon: Plus },
  { key: "orders", label: "Orders", href: "/dashboard/orders", icon: Package },
  { key: "vault", label: "Vault", href: "/dashboard/vault", icon: Ruler },
  { key: "profile", label: "Profile", href: "/dashboard/profile", icon: User },
  { key: "settings", label: "Settings", href: "/dashboard/settings", icon: Settings },
];

export interface NavRailProps {
  items?: NavRailItemSpec[];
  activeKey: string;
  /** collapsed 72 / expanded 244; page shells expand at ≥1264px. */
  expanded?: boolean;
  supportHref?: string;
  className?: string;
}

export function NavRail({
  items = DEFAULT_NAV_ITEMS,
  activeKey,
  expanded = false,
  supportHref = "https://clients.cuesoft.io",
  className,
}: NavRailProps) {
  const { preference, setPreference } = useTheme();
  const nextTheme = preference === "dark" ? "light" : "dark";
  return (
    <nav
      data-expanded={expanded}
      aria-label="Primary"
      className={clsx(
        "flex h-full flex-col border-r border-border bg-bg px-3 py-4",
        expanded ? "w-[244px]" : "w-[72px]",
        className,
      )}
    >
      {/* Figma master (84:1046): gradient brandmark heads the rail */}
      <div
        className={clsx(
          "flex h-12 items-center pb-2",
          expanded ? "px-3" : "justify-center",
        )}
      >
        <span className="bg-accent-gradient bg-clip-text text-title font-bold text-transparent">
          {expanded ? "Apparule" : "A"}
        </span>
      </div>
      <ul className="flex flex-1 flex-col gap-1">
        {items.map((item) => (
          <li key={item.key}>
            <NavRailItem
              item={item}
              expanded={expanded}
              active={item.key === activeKey}
            />
          </li>
        ))}
      </ul>
      <div className="flex flex-col gap-1 pt-3">
        <button
          type="button"
          onClick={() => setPreference(nextTheme)}
          aria-label={`Switch to ${nextTheme} theme`}
          className={itemClasses(false, expanded)}
        >
          {preference === "dark" ? <Sun size={24} /> : <Moon size={24} />}
          {expanded ? <span>Theme</span> : null}
        </button>
        <a
          href={supportHref}
          target="_blank"
          rel="noopener noreferrer"
          className={itemClasses(false, expanded)}
        >
          <Info size={24} />
          {expanded ? <span>Support</span> : null}
        </a>
      </div>
    </nav>
  );
}

// Figma master (84:902): 48px items, 14px labels; default reads text-2,
// active binds to text with a semibold label + accent dot; hover tints.
function itemClasses(active: boolean, expanded: boolean): string {
  return clsx(
    "relative flex h-12 items-center gap-3 rounded-card px-3 text-body",
    "transition-colors duration-120 ease-standard hover:bg-border/30 motion-reduce:transition-none",
    active ? "font-semibold text-text" : "text-text-2 hover:text-text",
    !expanded && "justify-center px-0",
  );
}

export function NavRailItem({
  item,
  active,
  expanded,
}: {
  item: NavRailItemSpec;
  active: boolean;
  expanded: boolean;
}) {
  const Icon = item.icon;
  return (
    <Link
      href={item.href}
      aria-current={active ? "page" : undefined}
      data-state={active ? "active" : "default"}
      className={itemClasses(active, expanded)}
    >
      <span className="relative">
        {active ? (
          <span
            data-testid="nav-active-dot"
            className="absolute -left-2 top-1/2 size-1 -translate-y-1/2 rounded-pill bg-accent-gradient"
          />
        ) : null}
        <Icon size={24} />
        {item.badge ? (
          <span
            data-testid="nav-badge"
            className="tnum absolute -right-2 -top-1.5 grid min-w-4 place-items-center rounded-pill bg-like px-1 text-[10px] font-semibold leading-4 text-on-accent"
          >
            {item.badge}
          </span>
        ) : null}
      </span>
      {expanded ? <span>{item.label}</span> : null}
    </Link>
  );
}
