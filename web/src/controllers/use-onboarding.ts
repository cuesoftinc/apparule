"use client";

// Designer onboarding + KYC controller (B8, flows/designer.md §1): intro →
// profile (display name/bio → POST /designer-profile) → banking form with
// the scripted Paystack resolution states (resolving → resolved-name
// confirm / mismatch error; support link after 3 fails) → done.
import { useCallback, useEffect, useState } from "react";
import type { BankResolution, DesignerProfile } from "@/models";
import { ApiError } from "@/lib/api";
import { designerRepo } from "@/models/repositories/designer-repo";
import { profilesRepo } from "@/models/repositories/profiles-repo";

export type OnboardingStep = "intro" | "profile" | "banking" | "done";
export type ResolutionState =
  | { phase: "idle" }
  | { phase: "resolving" }
  | { phase: "resolved"; resolution: BankResolution }
  | { phase: "failed"; message: string };

export const SUPPORT_URL = "https://clients.cuesoft.io";
/** Retry + support link after 3 resolution fails (pages.md B8). */
export const MAX_RESOLUTION_FAILS = 3;

export function useOnboarding(existingDesignerUsername: string | null = null) {
  const [step, setStep] = useState<OnboardingStep>("intro");
  const [profile, setProfile] = useState<DesignerProfile | null>(null);
  /** Current payout account for returning designers (KYC-lapse banner). */
  const [existingPayout, setExistingPayout] = useState<
    DesignerProfile["payout_account"] | null
  >(null);

  useEffect(() => {
    if (!existingDesignerUsername) return;
    let cancelled = false;
    profilesRepo.get(existingDesignerUsername).then(
      (fetched) => {
        if (cancelled || fetched.kind !== "designer") return;
        setExistingPayout(fetched.designer.payout_account);
      },
      () => {
        // no designer profile yet — nothing to show
      },
    );
    return () => {
      cancelled = true;
    };
  }, [existingDesignerUsername]);
  const [profileError, setProfileError] = useState<string | null>(null);
  const [enabling, setEnabling] = useState(false);
  const [resolution, setResolution] = useState<ResolutionState>({
    phase: "idle",
  });
  const [failCount, setFailCount] = useState(0);
  const [attaching, setAttaching] = useState(false);
  const [payout, setPayout] = useState<DesignerProfile["payout_account"] | null>(
    null,
  );

  const begin = useCallback(() => setStep("profile"), []);

  const enable = useCallback(async (displayName: string, bio: string) => {
    if (!displayName.trim()) {
      setProfileError("Display name is required");
      return;
    }
    setEnabling(true);
    setProfileError(null);
    try {
      const created = await designerRepo.enable(displayName.trim(), bio.trim());
      setProfile(created);
      setStep("banking");
    } catch (e) {
      setProfileError(
        e instanceof ApiError ? e.message : "Could not enable the profile",
      );
    } finally {
      setEnabling(false);
    }
  }, []);

  /** Paystack resolution — resolving spinner → resolved name / mismatch. */
  const resolve = useCallback(async (bankCode: string, accountNumber: string) => {
    setResolution({ phase: "resolving" });
    try {
      const resolved = await designerRepo.resolveBank(bankCode, accountNumber);
      setResolution({ phase: "resolved", resolution: resolved });
      setFailCount(0);
    } catch (e) {
      setFailCount((n) => n + 1);
      setResolution({
        phase: "failed",
        message:
          e instanceof ApiError
            ? e.message
            : "Could not resolve that account number",
      });
    }
  }, []);

  const resetResolution = useCallback(
    () => setResolution({ phase: "idle" }),
    [],
  );

  /** Confirm the resolved name → attach the payout account (KYC). */
  const attach = useCallback(async () => {
    if (resolution.phase !== "resolved") return;
    setAttaching(true);
    try {
      const attached = await designerRepo.attachPayoutAccount(
        resolution.resolution.bank_code,
        resolution.resolution.account_number,
      );
      setPayout(attached);
      setStep("done");
    } catch (e) {
      setResolution({
        phase: "failed",
        message:
          e instanceof ApiError ? e.message : "Could not attach the account",
      });
      setFailCount((n) => n + 1);
    } finally {
      setAttaching(false);
    }
  }, [resolution]);

  return {
    step,
    begin,
    enable,
    enabling,
    profile,
    profileError,
    existingPayout,
    resolve,
    resolution,
    resetResolution,
    failCount,
    showSupportLink: failCount >= MAX_RESOLUTION_FAILS,
    attach,
    attaching,
    payout,
  };
}
