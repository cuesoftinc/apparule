// B4 — Measurement vault (web-implementation.md §4 route map).
import type { Metadata } from "next";
import { VaultView } from "@/components/dashboard/vault/VaultView";

export const metadata: Metadata = {
  title: "Vault — Apparule",
};

export default function VaultPage() {
  return <VaultView />;
}
