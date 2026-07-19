"use client";

// B8 — Designer onboarding & KYC (flows/designer.md §1): intro (what you
// get) → profile → banking form with the Paystack resolution states
// (resolving spinner → resolved account-name confirm / mismatch error,
// retry + support link after 3 fails) → done. Shows the KYC-lapse banner
// when the payout account lapses. Render-only over useOnboarding.
import { useState } from "react";
import Link from "next/link";
import { BadgeCheck, Banknote, Shirt } from "lucide-react";
import { useAuth } from "@/controllers/auth/AuthContext";
import {
  SUPPORT_URL,
  useOnboarding,
} from "@/controllers/use-onboarding";
import { Banner } from "@/components/ui/Banner";
import { Button } from "@/components/ui/Button";
import { FormRow } from "@/components/ui/FormRow";
import { Input } from "@/components/ui/Input";
import { Select } from "@/components/ui/Select";
import { Spinner } from "@/components/ui/Spinner";

const BANKS = [
  { value: "058", label: "GTBank" },
  { value: "044", label: "Access Bank" },
  { value: "057", label: "Zenith Bank" },
  { value: "011", label: "First Bank" },
  { value: "033", label: "UBA" },
];

export function OnboardingView() {
  const { account } = useAuth();
  const alreadyDesigner = account?.designer.enabled ?? false;
  const onboarding = useOnboarding(
    alreadyDesigner ? (account?.username ?? null) : null,
  );
  const [displayName, setDisplayName] = useState("");
  const [bio, setBio] = useState("");
  const [bankCode, setBankCode] = useState<string | undefined>();
  const [accountNumber, setAccountNumber] = useState("");

  // Returning designers land on the banking step (payout status row → B8).
  const step =
    onboarding.step === "intro" && alreadyDesigner
      ? "banking"
      : onboarding.step;
  const kycLapsed = onboarding.existingPayout?.kyc_state === "lapsed";

  const canResolve =
    bankCode !== undefined && /^\d{10}$/.test(accountNumber.trim());

  return (
    <div className="mx-auto flex max-w-xl flex-col gap-6 px-4 py-6">
      <header>
        <h1 className="text-title-lg font-bold text-text">
          Designer onboarding
        </h1>
      </header>

      {kycLapsed ? (
        <div data-testid="kyc-lapse-banner">
          <Banner tone="warn">
            Your payout verification lapsed — posts can&apos;t accept new
            requests and payouts queue until you re-verify below.
          </Banner>
        </div>
      ) : null}

      {step === "intro" ? (
        <section aria-label="What you get" className="flex flex-col gap-4">
          <ul className="flex flex-col gap-3 text-body text-text">
            <li className="flex items-start gap-3">
              <Shirt size={24} className="shrink-0 text-text-2" aria-hidden />
              Publish outfits with your pricing and turnaround — your grid is
              your storefront.
            </li>
            <li className="flex items-start gap-3">
              <BadgeCheck
                size={24}
                className="shrink-0 text-text-2"
                aria-hidden
              />
              Receive commission requests with exact measurements attached.
            </li>
            <li className="flex items-start gap-3">
              <Banknote size={24} className="shrink-0 text-text-2" aria-hidden />
              Get paid through escrow — released on delivery, 10% platform fee.
            </li>
          </ul>
          <p className="text-caption text-text-2">
            You can post right away; accepting requests unlocks after payout
            verification (bank account, via Paystack).
          </p>
          <div>
            <Button
              kind="gradient-primary"
              onClick={onboarding.begin}
              data-testid="onboarding-start"
            >
              Get started
            </Button>
          </div>
        </section>
      ) : null}

      {step === "profile" ? (
        <form
          aria-label="Create your designer profile"
          className="flex flex-col gap-4"
          onSubmit={(e) => {
            e.preventDefault();
            void onboarding.enable(displayName, bio);
          }}
        >
          {onboarding.profileError ? (
            <Banner tone="error">{onboarding.profileError}</Banner>
          ) : null}
          <FormRow label="Display name" required>
            <Input
              aria-label="Display name"
              placeholder="Kiki Ade Studio"
              value={displayName}
              onChange={(e) => setDisplayName(e.target.value)}
            />
          </FormRow>
          <FormRow label="Bio" helper="What do you make? Who for?">
            <Input
              kind="textarea"
              aria-label="Bio"
              placeholder="Ankara & contemporary tailoring…"
              maxLength={500}
              value={bio}
              onChange={(e) => setBio(e.target.value)}
            />
          </FormRow>
          <footer>
            <Button
              kind="gradient-primary"
              type="submit"
              loading={onboarding.enabling}
              disabled={displayName.trim().length === 0}
              data-testid="onboarding-create-profile"
            >
              Create profile
            </Button>
          </footer>
        </form>
      ) : null}

      {step === "banking" ? (
        <section aria-label="Payout account" className="flex flex-col gap-4">
          <p className="text-body text-text-2">
            Payouts land in this account after delivery confirmation. We verify
            it with Paystack.
          </p>
          <form
            className="flex flex-col gap-4"
            onSubmit={(e) => {
              e.preventDefault();
              if (canResolve && bankCode) {
                void onboarding.resolve(bankCode, accountNumber.trim());
              }
            }}
          >
            <FormRow label="Bank" required>
              <Select
                aria-label="Bank"
                placeholder="Pick your bank"
                options={BANKS}
                value={bankCode}
                onValueChange={(v) => {
                  setBankCode(v);
                  onboarding.resetResolution();
                }}
              />
            </FormRow>
            <FormRow label="Account number" helper="10 digits (NUBAN)" required>
              <Input
                aria-label="Account number"
                inputMode="numeric"
                placeholder="0123456789"
                value={accountNumber}
                maxLength={10}
                onChange={(e) => {
                  setAccountNumber(e.target.value.replace(/\D/g, ""));
                  onboarding.resetResolution();
                }}
                data-testid="account-number"
              />
            </FormRow>

            {onboarding.resolution.phase === "resolving" ? (
              <p
                aria-live="polite"
                className="flex items-center gap-2 text-body text-text-2"
                data-testid="resolving"
              >
                <Spinner size={20} kind="neutral" /> Resolving account…
              </p>
            ) : null}

            {onboarding.resolution.phase === "failed" ? (
              <Banner tone="error">
                {onboarding.resolution.message}
                {onboarding.showSupportLink ? (
                  <>
                    {" "}
                    Still stuck?{" "}
                    <a
                      href={SUPPORT_URL}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="underline"
                    >
                      Contact support
                    </a>
                    .
                  </>
                ) : null}
              </Banner>
            ) : null}

            {onboarding.resolution.phase === "resolved" ? (
              <div
                className="flex flex-col gap-3 rounded-card border border-border p-4"
                data-testid="resolved-name"
              >
                <p className="text-body text-text">
                  Account name:{" "}
                  <strong>{onboarding.resolution.resolution.account_name}</strong>
                </p>
                <p className="text-caption text-text-2">
                  Confirm this is you — payouts are irreversible.
                </p>
                <div className="flex gap-2">
                  <Button
                    kind="gradient-primary"
                    loading={onboarding.attaching}
                    onClick={() => void onboarding.attach()}
                    data-testid="confirm-account"
                  >
                    Yes, attach this account
                  </Button>
                  <Button kind="quiet" onClick={onboarding.resetResolution}>
                    Edit details
                  </Button>
                </div>
              </div>
            ) : (
              <footer>
                <Button
                  kind="gradient-primary"
                  type="submit"
                  disabled={
                    !canResolve || onboarding.resolution.phase === "resolving"
                  }
                  data-testid="resolve-account"
                >
                  Verify account
                </Button>
              </footer>
            )}
          </form>
        </section>
      ) : null}

      {step === "done" ? (
        <section
          aria-label="Onboarding complete"
          className="flex flex-col items-center gap-4 py-8 text-center"
          data-testid="onboarding-done"
        >
          <span
            aria-hidden
            className="flex h-14 w-14 items-center justify-center rounded-full bg-accent-gradient text-title text-on-accent"
          >
            ✓
          </span>
          <h2 className="text-title font-bold text-text">
            {onboarding.payout?.kyc_state === "verified"
              ? "You're a verified designer"
              : "Profile created"}
          </h2>
          <p className="max-w-sm text-body text-text-2">
            {onboarding.payout?.kyc_state === "verified"
              ? "Your posts can accept requests, and payouts release to your account on delivery."
              : "Your bank details attached, but verification is pending — posts accept requests once it clears."}
          </p>
          <div className="flex gap-2">
            <Link
              href="/dashboard/create"
              className="inline-flex h-11 items-center justify-center rounded-card bg-accent-gradient px-4 text-body font-semibold text-on-accent"
            >
              Post your first outfit
            </Link>
            <Link
              href="/dashboard/earnings"
              className="inline-flex h-11 items-center justify-center rounded-card border border-border px-4 text-body font-semibold text-text"
            >
              View earnings
            </Link>
          </div>
        </section>
      ) : null}
    </div>
  );
}
