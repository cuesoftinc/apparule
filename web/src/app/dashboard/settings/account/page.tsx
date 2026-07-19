// B7 sub-screen — Account & data (web-implementation.md §4 route map).
import type { Metadata } from "next";
import { AccountDataView } from "@/components/dashboard/settings/AccountDataView";

export const metadata: Metadata = {
  title: "Account & data — Apparule",
};

export default function AccountDataPage() {
  return <AccountDataView />;
}
