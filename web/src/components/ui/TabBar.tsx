"use client";

// TabBar — design.md §8.2: active tab ×5 · Orders badge: none / count.
// Bottom tab bar Home · Explore · ➕ · Orders · Profile (design.md §3,
// pages.md Part C chrome — shared component naming web ⇄ Flutter).
// MI-16: the Orders badge increments with a springy scale pop and clears
// on tab visit (clearing is the page shell's job).
import Link from "next/link";
import clsx from "clsx";
import {
  Compass,
  Home,
  Package,
  PlusSquare,
  User,
  type LucideIcon,
} from "lucide-react";

export interface TabBarItemSpec {
  key: string;
  label: string;
  href: string;
  icon: LucideIcon;
}

export const DEFAULT_TAB_ITEMS: TabBarItemSpec[] = [
  { key: "home", label: "Home", href: "/dashboard", icon: Home },
  { key: "explore", label: "Explore", href: "/dashboard/explore", icon: Compass },
  { key: "create", label: "Create", href: "/dashboard/create", icon: PlusSquare },
  { key: "orders", label: "Orders", href: "/dashboard/orders", icon: Package },
  { key: "profile", label: "Profile", href: "/dashboard/profile", icon: User },
];

export interface TabBarProps {
  items?: TabBarItemSpec[];
  activeKey: string;
  /** MI-16: unread Orders count — none / count. */
  ordersBadge?: number;
  className?: string;
}

export function TabBar({
  items = DEFAULT_TAB_ITEMS,
  activeKey,
  ordersBadge,
  className,
}: TabBarProps) {
  return (
    <nav
      aria-label="Tabs"
      className={clsx(
        "flex h-12 items-stretch border-t border-border bg-bg",
        className,
      )}
    >
      {items.map((item) => {
        const Icon = item.icon;
        const active = item.key === activeKey;
        const badge = item.key === "orders" ? ordersBadge : undefined;
        return (
          <Link
            key={item.key}
            href={item.href}
            aria-label={item.label}
            aria-current={active ? "page" : undefined}
            data-state={active ? "active" : "default"}
            className={clsx(
              "relative flex flex-1 items-center justify-center text-text",
              "transition-colors duration-120 ease-standard motion-reduce:transition-none",
              !active && "text-text-2 hover:text-text",
            )}
          >
            <span className="relative">
              <Icon size={24} strokeWidth={active ? 2.5 : 2} />
              {badge ? (
                <span
                  key={badge}
                  data-testid="tab-badge"
                  className={clsx(
                    "tnum absolute -right-2 -top-1.5 grid min-w-4 place-items-center rounded-pill bg-like px-1 text-[10px] font-bold leading-4 text-on-accent",
                    "animate-[pop-in_300ms_var(--ap-ease-standard)] motion-reduce:animate-none",
                  )}
                >
                  {badge}
                </span>
              ) : null}
            </span>
          </Link>
        );
      })}
    </nav>
  );
}
