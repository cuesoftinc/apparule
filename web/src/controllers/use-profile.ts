"use client";

// Profile controller — own account editing (username claim/rename, location)
// per pages.md B6/B7; designer enablement + earnings via designerRepo.
import { useCallback, useEffect, useState } from "react";
import type { Account, DesignerProfile, Earnings } from "@/models";
import { ApiError } from "@/lib/api";
import {
  accountRepo,
  type AccountPatch,
} from "@/models/repositories/account-repo";
import { designerRepo } from "@/models/repositories/designer-repo";
import { profilesRepo } from "@/models/repositories/profiles-repo";

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

export function useEarnings(ownUsername: string | null = null) {
  const [earnings, setEarnings] = useState<Earnings | null>(null);
  // Non-designers (ownUsername null) never hit the endpoint — it would be a
  // guaranteed 403 (console noise on every visit); the hook boots straight
  // into the B9 upsell state instead.
  const [loading, setLoading] = useState(ownUsername !== null);
  const [error, setError] = useState<string | null>(
    ownUsername ? null : "Earnings are available to designer profiles only",
  );
  /** Taxonomy code (e.g. designer_profile_required → B9 upsell state). */
  const [errorCode, setErrorCode] = useState<string | null>(
    ownUsername ? null : "designer_profile_required",
  );
  /** Payout-account card data (Figma 210:3) — own designer profile. */
  const [payoutAccount, setPayoutAccount] = useState<
    DesignerProfile["payout_account"] | null
  >(null);

  useEffect(() => {
    if (!ownUsername) return;
    let cancelled = false;
    profilesRepo.get(ownUsername).then(
      (fetched) => {
        if (cancelled || fetched.kind !== "designer") return;
        setPayoutAccount(fetched.designer.payout_account);
      },
      () => {
        // no designer profile — the upsell state covers it
      },
    );
    return () => {
      cancelled = true;
    };
  }, [ownUsername]);

  const load = useCallback(
    () =>
      designerRepo.earnings().then(
        (fetched) => {
          setEarnings(fetched);
          setError(null);
          setErrorCode(null);
          setLoading(false);
        },
        (e: unknown) => {
          setError(e instanceof Error ? e.message : "Failed to load earnings");
          setErrorCode(e instanceof ApiError ? e.code : null);
          setLoading(false);
        },
      ),
    [],
  );

  useEffect(() => {
    if (!ownUsername) return; // upsell state set at init — nothing to fetch
    void load();
  }, [load, ownUsername]);

  const reload = useCallback(() => {
    setLoading(true);
    setError(null);
    setErrorCode(null);
    return load();
  }, [load]);

  return { earnings, loading, error, errorCode, payoutAccount, reload };
}
