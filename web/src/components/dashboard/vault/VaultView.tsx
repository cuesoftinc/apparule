"use client";

// B4 — Measurement vault: freshness-ring header (MI-11) + Retake CTA →
// capture options (webcam upload / manual entry MI-13) · MeasurementCard
// grid with history sparklines · history sheet (SessionRow + delete) ·
// consent/retention notice with the rights links (resolve at B7 Account &
// data). Render-only over useVault.
import { useMemo, useState } from "react";
import Link from "next/link";
import { formatAgo } from "@/lib/format";
import type { MeasurementSession } from "@/models";
import { useAuth } from "@/controllers/auth/AuthContext";
import { useVault } from "@/controllers/use-vault";
import { Avatar } from "@/components/ui/Avatar";
import { Banner } from "@/components/ui/Banner";
import { Button } from "@/components/ui/Button";
import { EmptyState } from "@/components/ui/EmptyState";
import { MeasurementCard } from "@/components/ui/MeasurementCard";
import { SessionRow } from "@/components/ui/SessionRow";
import { Sheet } from "@/components/ui/Sheet";
import { Skeleton } from "@/components/ui/Skeleton";
import {
  CaptureOptionsSheet,
  ManualEntrySheet,
  WebcamCaptureSheet,
} from "./CaptureSheets";
import { useToasts } from "../toast-context";

const RING: Record<string, "gradient" | "amber" | "gray"> = {
  fresh: "gradient",
  aging: "amber",
  stale: "gray",
};

export function VaultView() {
  const { account } = useAuth();
  const vault = useVault();
  const { showToast } = useToasts();
  const [sheet, setSheet] = useState<
    null | "options" | "webcam" | "manual" | "history"
  >(null);

  const sessionById = useMemo(() => {
    const map = new Map<string, MeasurementSession>();
    for (const session of vault.sessions) map.set(session.id, session);
    return map;
  }, [vault.sessions]);

  /** Oldest → newest values per metric for the sparkline. */
  const historyFor = (name: string): number[] =>
    [...vault.sessions]
      .filter((s) => s.status === "complete")
      .sort(
        (a, b) =>
          new Date(a.created_at).getTime() - new Date(b.created_at).getTime(),
      )
      .flatMap((s) =>
        s.measurements.filter((m) => m.name === name).map((m) => m.value_cm),
      );

  const latestComplete = vault.sessions.find((s) => s.status === "complete");

  return (
    <div className="mx-auto flex max-w-2xl flex-col gap-6 px-4 py-6">
      <header className="flex items-center gap-4">
        <Avatar
          size={96}
          name={account?.display_name ?? "You"}
          ring={vault.freshness ? RING[vault.freshness] : "gray"}
        />
        <div className="min-w-0 flex-1">
          <h1 className="text-title-lg font-bold text-text">Vault</h1>
          <p className="text-body text-text-2">
            {latestComplete
              ? `Measured ${formatAgo(latestComplete.created_at)} ago`
              : "No measurements yet"}
          </p>
        </div>
        <Button
          kind="gradient-primary"
          onClick={() => setSheet("options")}
          data-testid="vault-retake"
        >
          {latestComplete ? "Retake" : "Get measured"}
        </Button>
      </header>

      {vault.loading ? (
        <div aria-busy="true" className="grid grid-cols-2 gap-4">
          <Skeleton kind="card" />
          <Skeleton kind="card" />
        </div>
      ) : vault.error ? (
        <EmptyState
          context="vault"
          line="The vault couldn't load — try again."
          ctaLabel="Retry"
          onCta={() => void vault.reload()}
        />
      ) : vault.latest.length === 0 ? (
        <EmptyState
          context="vault"
          ctaLabel="Get measured"
          onCta={() => setSheet("options")}
        />
      ) : (
        <section aria-labelledby="vault-metrics-h">
          <h2 id="vault-metrics-h" className="sr-only">
            Latest measurements
          </h2>
          <ul className="grid grid-cols-1 gap-4 sm:grid-cols-2" data-testid="vault-grid">
            {vault.latest.map((measurement) => {
              const session = sessionById.get(measurement.session_id);
              return (
                <li key={measurement.name}>
                  <MeasurementCard
                    name={measurement.name}
                    valueCm={measurement.value_cm}
                    source={session?.method === "manual" ? "manual" : "scan"}
                    confidence={measurement.confidence}
                    history={historyFor(measurement.name)}
                    updatedAt={session?.created_at ?? null}
                    onClick={() => setSheet("history")}
                  />
                </li>
              );
            })}
          </ul>
        </section>
      )}

      <Banner tone="info" actionLabel="Manage my data"
        onAction={() => window.location.assign("/dashboard/settings/account")}
      >
        Your measurements are private — a designer only ever sees the frozen
        snapshot inside an order you place. Capture photos auto-delete after
        30 days; measurements stay until you delete them.
      </Banner>
      <p className="text-caption text-text-2">
        <Link href="/dashboard/settings/account" className="text-link">
          Download my data
        </Link>{" "}
        ·{" "}
        <Link href="/dashboard/settings/account" className="text-link">
          Delete all
        </Link>
      </p>

      <CaptureOptionsSheet
        open={sheet === "options"}
        onOpenChange={(open) => setSheet(open ? "options" : null)}
        onPick={(mode) => setSheet(mode === "webcam-upload" ? "webcam" : "manual")}
      />
      <WebcamCaptureSheet
        open={sheet === "webcam"}
        onOpenChange={(open) => setSheet(open ? "webcam" : null)}
        onSaved={() => {
          showToast({ kind: "success", message: "Saved to your vault" });
          void vault.reload();
        }}
      />
      <ManualEntrySheet
        open={sheet === "manual"}
        onOpenChange={(open) => setSheet(open ? "manual" : null)}
        onSave={async (heightCm, measurements) => {
          await vault.addManualSession(heightCm, measurements);
          showToast({ kind: "success", message: "Saved to your vault" });
        }}
      />
      <Sheet
        open={sheet === "history"}
        onOpenChange={(open) => setSheet(open ? "history" : null)}
        title="Measurement history"
      >
        {vault.sessions.length === 0 ? (
          <p className="text-body text-text-2">No sessions yet.</p>
        ) : (
          <ul className="flex flex-col" data-testid="history-list">
            {vault.sessions.map((session) => (
              <li key={session.id}>
                <SessionRow
                  session={session}
                  onDelete={() =>
                    vault.deleteSession(session.id).then(
                      () =>
                        showToast({ kind: "neutral", message: "Session deleted" }),
                      () =>
                        showToast({
                          kind: "error",
                          message: "Couldn't delete the session",
                        }),
                    )
                  }
                />
              </li>
            ))}
          </ul>
        )}
      </Sheet>
    </div>
  );
}
