"use client";

// /dashboard/profile → the signed-in account's canonical B6 route
// (`/dashboard/{username}`) — keeps the NavRail's static href working
// before the account loads.
import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/auth/AuthContext";
import { Spinner } from "@/components/ui/Spinner";

export function ProfileRedirect() {
  const { status, account } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (status === "signed_in" && account) {
      router.replace(`/dashboard/${account.username}`);
    }
  }, [status, account, router]);

  return (
    <div aria-busy="true" className="flex justify-center py-24">
      <Spinner size={28} kind="gradient" />
      <span className="sr-only">Opening your profile…</span>
    </div>
  );
}
