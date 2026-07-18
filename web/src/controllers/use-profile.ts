"use client";

// Profile controller — own account editing (username claim/rename, location)
// per pages.md B6/B7; designer enablement + earnings via designerRepo.
import { useCallback, useEffect, useState } from "react";
import type { Account, Earnings } from "@/models";
import { ApiError } from "@/lib/api";
import {
  accountRepo,
  type AccountPatch,
} from "@/models/repositories/account-repo";
import { designerRepo } from "@/models/repositories/designer-repo";

export function useProfile() {
  const [account, setAccount] = useState<Account | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Effect-safe fetch (react-hooks/set-state-in-effect): setState only in
  // promise callbacks; reload() re-arms loading from event handlers.
  const load = useCallback(
    () =>
      accountRepo.me().then(
        (me) => {
          setAccount(me);
          setError(null);
          setLoading(false);
        },
        (e: unknown) => {
          setError(e instanceof Error ? e.message : "Failed to load profile");
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

  const update = useCallback(async (patch: AccountPatch) => {
    try {
      const updated = await accountRepo.updateMe(patch);
      setAccount(updated);
      return { ok: true as const };
    } catch (e) {
      if (e instanceof ApiError && e.code === "name_taken") {
        return { ok: false as const, code: e.code, message: e.message };
      }
      throw e;
    }
  }, []);

  return { account, loading, error, reload, update };
}

export function useEarnings() {
  const [earnings, setEarnings] = useState<Earnings | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(
    () =>
      designerRepo.earnings().then(
        (fetched) => {
          setEarnings(fetched);
          setError(null);
          setLoading(false);
        },
        (e: unknown) => {
          setError(e instanceof Error ? e.message : "Failed to load earnings");
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

  return { earnings, loading, error, reload };
}
