"use client";

// Dashboard shell (pages.md Part B chrome): left NavRail (collapsed 72,
// expanded 244 at ≥1264px), auth guard, Orders badge (MI-16 — clears on tab
// visit), and the single <main> landmark every screen renders into.
import { useEffect, useMemo, type ReactNode } from "react";
import { usePathname, useRouter } from "next/navigation";
import { useAuth } from "@/controllers/auth/AuthContext";
import { useNotifications } from "@/controllers/use-notifications";
import { NavRail, DEFAULT_NAV_ITEMS } from "@/components/ui/NavRail";
import { Spinner } from "@/components/ui/Spinner";
import { ToastProvider } from "./toast-context";

function activeKeyFor(pathname: string, ownUsername: string | null): string {
  if (pathname === "/dashboard") return "home";
  if (pathname.startsWith("/dashboard/explore")) return "explore";
  if (pathname.startsWith("/dashboard/create")) return "create";
  if (pathname.startsWith("/dashboard/orders")) return "orders";
  if (pathname.startsWith("/dashboard/vault")) return "vault";
  if (pathname.startsWith("/dashboard/settings")) return "settings";
  if (
    pathname === "/dashboard/profile" ||
    (ownUsername !== null && pathname === `/dashboard/${ownUsername}`)
  ) {
    return "profile";
  }
  return "";
}

export function DashboardShell({ children }: { children: ReactNode }) {
  const { status, account } = useAuth();
  const router = useRouter();
  const pathname = usePathname();
  const { ordersBadge, markOrderKindsRead } = useNotifications();

  // Auth guard: the dashboard is the authenticated app (web-implementation
  // §4) — signed-out visitors land on /signin.
  useEffect(() => {
    if (status === "signed_out") {
      router.replace("/signin");
    }
  }, [status, router]);

  // MI-16: the Orders badge clears on tab visit. Marking flips the badge to
  // 0, so the guard prevents re-runs (no loop despite the changing callback).
  const onOrdersTab = pathname.startsWith("/dashboard/orders");
  useEffect(() => {
    if (onOrdersTab && ordersBadge > 0) {
      void markOrderKindsRead();
    }
  }, [onOrdersTab, ordersBadge, markOrderKindsRead]);

  const items = useMemo(
    () =>
      DEFAULT_NAV_ITEMS.map((item) => {
        if (item.key === "orders") {
          return { ...item, badge: ordersBadge > 0 ? ordersBadge : undefined };
        }
        if (item.key === "profile" && account) {
          return { ...item, href: `/dashboard/${account.username}` };
        }
        return item;
      }),
    [ordersBadge, account],
  );

  const activeKey = activeKeyFor(pathname, account?.username ?? null);

  if (status === "loading" || status === "signed_out") {
    return (
      <main
        aria-busy="true"
        className="flex min-h-screen items-center justify-center"
      >
        <Spinner size={28} kind="gradient" />
        <span className="sr-only">Loading…</span>
      </main>
    );
  }

  return (
    <ToastProvider>
      <div className="flex min-h-screen bg-bg">
        <div className="sticky top-0 h-screen shrink-0 min-[1264px]:hidden">
          <NavRail activeKey={activeKey} items={items} />
        </div>
        <div className="sticky top-0 hidden h-screen shrink-0 min-[1264px]:block">
          <NavRail activeKey={activeKey} items={items} expanded />
        </div>
        <main className="min-w-0 flex-1">{children}</main>
      </div>
    </ToastProvider>
  );
}
