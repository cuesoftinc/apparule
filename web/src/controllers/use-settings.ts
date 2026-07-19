"use client";

// Settings controller (B7 + sub-screens): notification prefs (optimistic
// toggles persisted via PATCH /me), consent history, data export, and the
// delete-all request (Account & data — the B4 rights links resolve here).
import { useCallback, useEffect, useState } from "react";
import type { Account, ConsentRecord, NotificationPrefs } from "@/models";
import { accountRepo } from "@/models/repositories/account-repo";

export function useSettings() {
  const [account, setAccount] = useState<Account | null>(null);
  const [consent, setConsent] = useState<ConsentRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [exporting, setExporting] = useState(false);
  const [deleting, setDeleting] = useState(false);

  const load = useCallback(
    () =>
      Promise.all([accountRepo.me(), accountRepo.consent()]).then(
        ([me, consentRecords]) => {
          setAccount(me);
          setConsent(consentRecords);
          setError(null);
          setLoading(false);
        },
        (e: unknown) => {
          setError(e instanceof Error ? e.message : "Failed to load settings");
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

  /** Optimistic per-event toggle (MI-18) — rolls back on failure. */
  const setPref = useCallback(
    async (key: keyof NotificationPrefs, value: boolean) => {
      let previous: boolean | null = null;
      setAccount((a) => {
        if (!a) return a;
        previous = a.notification_prefs[key];
        return {
          ...a,
          notification_prefs: { ...a.notification_prefs, [key]: value },
        };
      });
      try {
        const updated = await accountRepo.updateMe({
          notification_prefs: { [key]: value },
        });
        setAccount(updated);
      } catch {
        setAccount((a) =>
          a && previous !== null
            ? {
                ...a,
                notification_prefs: {
                  ...a.notification_prefs,
                  [key]: previous,
                },
              }
            : a,
        );
        throw new Error("pref_failed");
      }
    },
    [],
  );

  /** Profile location (X-10 tier 1) + display fields via PATCH /me. */
  const updateAccount = useCallback(
    async (patch: Parameters<typeof accountRepo.updateMe>[0]) => {
      const updated = await accountRepo.updateMe(patch);
      setAccount(updated);
      return updated;
    },
    [],
  );

  /** "Download my data" — returns the export blob URL for the view. */
  const exportData = useCallback(async (): Promise<string> => {
    setExporting(true);
    try {
      const data = await accountRepo.exportData();
      const blob = new Blob([JSON.stringify(data, null, 2)], {
        type: "application/json",
      });
      return URL.createObjectURL(blob);
    } finally {
      setExporting(false);
    }
  }, []);

  /** "Delete all" — confirm-gated in the view. */
  const requestDeletion = useCallback(async () => {
    setDeleting(true);
    try {
      const updated = await accountRepo.requestDeletion();
      setAccount(updated);
      return updated;
    } finally {
      setDeleting(false);
    }
  }, []);

  return {
    account,
    consent,
    loading,
    error,
    reload,
    setPref,
    updateAccount,
    exportData,
    exporting,
    requestDeletion,
    deleting,
  };
}
