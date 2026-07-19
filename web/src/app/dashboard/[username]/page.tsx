// B6 — Profiles (dynamic segment; static siblings win route precedence,
// web-implementation.md §4).
import type { Metadata } from "next";
import { ProfileView } from "@/components/dashboard/profile/ProfileView";

export const metadata: Metadata = {
  title: "Profile — Apparule",
};

export default async function ProfilePage({
  params,
}: {
  params: Promise<{ username: string }>;
}) {
  const { username } = await params;
  return <ProfileView username={decodeURIComponent(username)} />;
}
