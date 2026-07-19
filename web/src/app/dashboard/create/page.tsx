// B5 — Post an outfit / creator upsell (web-implementation.md §4 route map).
import type { Metadata } from "next";
import { ComposerView } from "@/components/dashboard/create/ComposerView";

export const metadata: Metadata = {
  title: "Create — Apparule",
};

export default function CreatePage() {
  return <ComposerView />;
}
