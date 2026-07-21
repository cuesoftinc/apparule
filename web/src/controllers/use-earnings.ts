"use client";

// Earnings controller — designer earnings + payout-account card (pages.md B9)
// via designerRepo/profilesRepo; non-designers boot into the upsell state.
import { useCallback, useEffect, useState } from "react";
import type { DesignerProfile, Earnings } from "@/models";
import { ApiError } from "@/lib/api";
import { designerRepo } from "@/models/repositories/designer-repo";
import { profilesRepo } from "@/models/repositories/profiles-repo";

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
