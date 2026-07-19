"use client";

// B7 sub-screen — Notifications: per-event toggles (quotes, order status,
// social, payouts) persisted through PATCH /me (optimistic, MI-18).
import { useRouter } from "next/navigation";
import type { NotificationPrefs } from "@/models";
import { useSettings } from "@/controllers/use-settings";
import { AppBar } from "@/components/ui/AppBar";
import { Skeleton } from "@/components/ui/Skeleton";
import { Switch } from "@/components/ui/Switch";
import { useToasts } from "../toast-context";

const PREF_ROWS: {
  key: keyof NotificationPrefs;
  title: string;
  meta: string;
}[] = [
  { key: "quotes", title: "Quotes", meta: "A designer answers your request" },
  {
    key: "order_status",
    title: "Order status",
    meta: "Paid, in progress, shipped, delivered",
  },
  { key: "social", title: "Social", meta: "Likes, follows, comments" },
  { key: "payouts", title: "Payouts", meta: "Escrow released to your account" },
];

export function NotificationSettingsView() {
  const { account, loading, setPref } = useSettings();
  const router = useRouter();
  const { showToast } = useToasts();

  return (
    <div className="mx-auto flex max-w-xl flex-col px-4 pb-10">
      <AppBar
        kind="sub"
        title="Notifications"
        onBack={() => router.push("/dashboard/settings")}
      />
      <h1 className="sr-only">Notification settings</h1>
      {loading || !account ? (
        <div aria-busy="true" className="py-6">
          <Skeleton kind="card" />
        </div>
      ) : (
        <ul className="divide-y divide-border">
          {PREF_ROWS.map((row) => (
            <li
              key={row.key}
              className="flex items-center justify-between gap-4 py-4"
            >
              <div>
                <p className="text-body font-semibold text-text">{row.title}</p>
                <p className="text-caption text-text-2">{row.meta}</p>
              </div>
              <Switch
                aria-label={row.title}
                checked={account.notification_prefs[row.key]}
                onCheckedChange={(checked) =>
                  setPref(row.key, checked).catch(() =>
                    showToast({
                      kind: "error",
                      message: "Couldn't save the preference",
                    }),
                  )
                }
              />
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
