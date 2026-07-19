// B7 sub-screen — Privacy & consent (web-implementation.md §4 route map).
import type { Metadata } from "next";
import { PrivacySettingsView } from "@/components/dashboard/settings/PrivacySettingsView";

export const metadata: Metadata = {
  title: "Privacy & consent — Apparule",
};

export default function PrivacySettingsPage() {
  return <PrivacySettingsView />;
}
