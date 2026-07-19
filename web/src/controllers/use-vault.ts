"use client";

// Vault controller — B4 state: session history, latest values per metric,
// freshness for the MI-11 ring, manual entry (MI-13).
import { useCallback, useEffect, useMemo, useState } from "react";
import type { Freshness, Measurement, MeasurementSession } from "@/models";
import { freshnessOf } from "@/models";
import {
  latestMeasurements,
  vaultRepo,
} from "@/models/repositories/vault-repo";

export function useVault() {
  const [sessions, setSessions] = useState<MeasurementSession[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Effect-safe fetch (react-hooks/set-state-in-effect): setState only in
  // promise callbacks; reload() re-arms loading from event handlers.
  const load = useCallback(
    () =>
      vaultRepo.sessions().then(
        (page) => {
          setSessions(page.items);
          setError(null);
          setLoading(false);
        },
        (e: unknown) => {
          setError(e instanceof Error ? e.message : "Failed to load vault");
          setLoading(false);
        },
      ),
    [],
  );

  useEffect(() => {
    void load();
  }, [load]);

  const reload = useCallback(() => {
    setLoading(true);
    setError(null);
    return load();
  }, [load]);

  const latest: Measurement[] = useMemo(
    () => latestMeasurements(sessions),
    [sessions],
  );

  /** Freshness of the newest complete session (drives the MI-11 ring). */
  const freshness: Freshness | null = useMemo(() => {
    const complete = sessions.filter((s) => s.status === "complete");
    if (complete.length === 0) return null;
    const newest = complete.reduce((a, b) =>
      new Date(a.created_at) > new Date(b.created_at) ? a : b,
    );
    return freshnessOf(newest.created_at);
  }, [sessions]);

  const addManualSession = useCallback(
    async (
      inputHeightCm: number,
      measurements: { name: string; value_cm: number }[],
    ) => {
      const session = await vaultRepo.createManualSession(
        { method: "manual", input_height_cm: inputHeightCm, measurements },
        crypto.randomUUID(),
      );
      setSessions((prev) => [session, ...prev]);
      return session;
    },
    [],
  );

  const deleteSession = useCallback(async (id: string) => {
    await vaultRepo.deleteSession(id);
    setSessions((prev) => prev.filter((s) => s.id !== id));
  }, []);

  /**
   * F2-9 session export: POST /sessions/{id}/exports → the signed URL
   * (an inline data URL in TEST_MODE) the view hands to the browser.
   */
  const exportSession = useCallback(
    (id: string, format: "csv" | "pdf") => vaultRepo.exportSession(id, format),
    [],
  );

  return {
    sessions,
    latest,
    freshness,
    loading,
    error,
    reload,
    addManualSession,
    deleteSession,
    exportSession,
  };
}
