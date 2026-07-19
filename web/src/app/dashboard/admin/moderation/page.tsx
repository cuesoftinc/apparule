// B7a — Moderation queue, staff only (web-implementation.md §4 route map).
import type { Metadata } from "next";
import { ModerationView } from "@/components/dashboard/moderation/ModerationView";

export const metadata: Metadata = {
  title: "Moderation — Apparule",
};

export default function ModerationPage() {
  return <ModerationView />;
}
