// B7 — Settings (web-implementation.md §4 route map).
import type { Metadata } from "next";
import { SettingsView } from "@/components/dashboard/settings/SettingsView";

export const metadata: Metadata = {
  title: "Settings — Apparule",
};

export default function SettingsPage() {
  return <SettingsView />;
}
