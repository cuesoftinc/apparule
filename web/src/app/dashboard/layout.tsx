// Dashboard segment layout — every Part B screen renders inside the shell
// (NavRail + auth guard + the page's single <main>).
import { DashboardShell } from "@/components/dashboard/DashboardShell";

export default function DashboardLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return <DashboardShell>{children}</DashboardShell>;
}
