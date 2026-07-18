"use client";

// Dashboard shell stub — W0 lands the authenticated landing target for the
// signin → dashboard smoke journey; the full B1 feed arrives in stage W3.
import Link from "next/link";
import { useAuth } from "@/controllers/auth/AuthContext";

export default function DashboardPage() {
  const { status, account } = useAuth();

  return (
    <main className="flex flex-1 flex-col items-center justify-center gap-4 px-6 py-16 text-center">
      <h1 className="text-title-lg font-bold">Dashboard</h1>
      {status === "loading" ? (
        <p className="text-body text-text-2">Loading…</p>
      ) : account ? (
        <p className="text-body text-text-2" data-testid="signed-in-as">
          Signed in as <span className="font-semibold text-text">@{account.username}</span>
        </p>
      ) : (
        <p className="text-body text-text-2">
          You&apos;re not signed in.{" "}
          <Link href="/signin" className="text-link">
            Sign in
          </Link>
        </p>
      )}
      <p className="max-w-md text-caption text-text-2">
        The feed, explore, orders, vault, and profile surfaces land in stage
        W3 (pages.md Part B).
      </p>
    </main>
  );
}
