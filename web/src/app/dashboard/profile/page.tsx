// /dashboard/profile — redirect helper to the canonical B6 profile route.
import type { Metadata } from "next";
import { ProfileRedirect } from "./ProfileRedirect";

export const metadata: Metadata = {
  title: "Profile — Apparule",
};

export default function ProfileRedirectPage() {
  return <ProfileRedirect />;
}
