// B4 — Measurement vault (web-implementation.md §4 route map). The Create
// chooser (M-11) hands off here with ?capture=1 to open the capture
// options sheet on landing.
import type { Metadata } from "next";
import { VaultView } from "@/components/dashboard/vault/VaultView";

export const metadata: Metadata = {
  title: "Vault — Apparule",
};

export default async function VaultPage({
  searchParams,
}: {
  searchParams: Promise<{ capture?: string }>;
}) {
  const { capture } = await searchParams;
  return <VaultView initialSheet={capture ? "options" : null} />;
}
