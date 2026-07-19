// B7 sub-screen — Notifications (web-implementation.md §4 route map).
import type { Metadata } from "next";
import { NotificationSettingsView } from "@/components/dashboard/settings/NotificationSettingsView";

export const metadata: Metadata = {
  title: "Notification settings — Apparule",
};

export default function NotificationSettingsPage() {
  return <NotificationSettingsView />;
}
