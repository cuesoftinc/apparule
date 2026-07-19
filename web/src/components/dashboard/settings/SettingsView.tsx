"use client";

// B7 — Settings: account (Google identity) · creator profile · payout
// account status (→ B8) · profile location (X-10 tier 1, optional with
// explainer) · links to the Notifications / Privacy & consent / Account &
// data sub-screens · language · theme. Render-only over useSettings.
import { useState } from "react";
import Link from "next/link";
import { ChevronRight, LogOut } from "lucide-react";
import { useRouter } from "next/navigation";
import type { DeliveryAddress } from "@/models";
import { useAuth } from "@/controllers/auth/AuthContext";
import { useSettings } from "@/controllers/use-settings";
import { useTheme } from "@/design/ThemeProvider";
import { AddressFieldset } from "@/components/ui/AddressFieldset";
import { Banner } from "@/components/ui/Banner";
import { Button } from "@/components/ui/Button";
import { Select } from "@/components/ui/Select";
import { Skeleton } from "@/components/ui/Skeleton";
import { StatusPill } from "@/components/ui/StatusPill";
import { useToasts } from "../toast-context";

function SettingsRow({
  title,
  meta,
  href,
  testId,
}: {
  title: string;
  meta?: string;
  href: string;
  testId?: string;
}) {
  return (
    <Link
      href={href}
      data-testid={testId}
      className="flex items-center justify-between gap-3 py-3 text-body text-text hover:bg-border/20"
    >
      <span className="flex flex-col">
        {title}
        {meta ? <span className="text-caption text-text-2">{meta}</span> : null}
      </span>
      <ChevronRight size={20} className="text-text-2" aria-hidden />
    </Link>
  );
}

export function SettingsView() {
  const { account, loading, error, reload, updateAccount } = useSettings();
  const auth = useAuth();
  const router = useRouter();
  const { preference, setPreference } = useTheme();
  const { showToast } = useToasts();
  const [savingLocation, setSavingLocation] = useState(false);
  const [location, setLocation] = useState<Partial<DeliveryAddress> | null>(
    null,
  );

  if (loading) {
    return (
      <div aria-busy="true" className="mx-auto max-w-xl px-4 py-6">
        <Skeleton kind="card" />
      </div>
    );
  }
  if (error || !account) {
    return (
      <div className="mx-auto max-w-xl px-4 py-16 text-center">
        <p role="alert" className="text-body text-text-2">
          Settings couldn&apos;t load.
        </p>
        <Button kind="quiet" onClick={() => void reload()}>
          Retry
        </Button>
      </div>
    );
  }

  const editedLocation =
    location ??
    (account.profile_location
      ? {
          city: account.profile_location.city,
          state: account.profile_location.state,
          country: account.profile_location.country,
        }
      : {});

  const saveLocation = async () => {
    setSavingLocation(true);
    try {
      const { city, state, country } = editedLocation;
      await updateAccount({
        profile_location:
          city && state && country ? { city, state, country } : null,
      });
      showToast({ kind: "success", message: "Location saved" });
      setLocation(null);
    } catch {
      showToast({ kind: "error", message: "Couldn't save your location" });
    } finally {
      setSavingLocation(false);
    }
  };

  return (
    <div className="mx-auto flex max-w-xl flex-col gap-6 px-4 py-6">
      <header>
        <h1 className="text-title-lg font-bold text-text">Settings</h1>
      </header>

      {account.deletion_state === "deletion_pending" ? (
        <Banner tone="warn">
          Account deletion requested — your data will be removed after the
          30-day grace period.
        </Banner>
      ) : null}

      <section aria-labelledby="settings-account-h">
        <h2
          id="settings-account-h"
          className="pb-1 text-body font-semibold text-text-2"
        >
          Account
        </h2>
        <p className="py-2 text-body text-text">
          {account.display_name}{" "}
          <span className="text-text-2">
            · @{account.username} · {account.email} (Google)
          </span>
        </p>
      </section>

      <section aria-labelledby="settings-creator-h">
        <h2
          id="settings-creator-h"
          className="pb-1 text-body font-semibold text-text-2"
        >
          Creator profile
        </h2>
        {account.designer.enabled ? (
          <div className="flex items-center justify-between py-2">
            <p className="text-body text-text">
              Designer profile active
              {account.designer.kyc_complete
                ? " — payouts verified"
                : " — payout verification pending"}
            </p>
            <StatusPill
              status={account.designer.kyc_complete ? "fresh" : "aging"}
            />
          </div>
        ) : (
          <SettingsRow
            title="Become a designer"
            meta="Post outfits, get commissioned, get paid"
            href="/dashboard/designer/onboarding"
            testId="settings-become-designer"
          />
        )}
        {account.designer.enabled ? (
          <SettingsRow
            title="Payout account"
            meta={
              account.designer.kyc_complete
                ? "Verified with Paystack"
                : "Finish verification to accept requests"
            }
            href="/dashboard/designer/onboarding"
            testId="settings-payout"
          />
        ) : null}
      </section>

      <section aria-labelledby="settings-location-h">
        <h2
          id="settings-location-h"
          className="pb-1 text-body font-semibold text-text-2"
        >
          Profile location
        </h2>
        <p className="pb-2 text-caption text-text-2">
          Optional — used to recommend nearby designers.
        </p>
        <AddressFieldset
          context="profile-location"
          value={editedLocation}
          onChange={setLocation}
        />
        {location !== null ? (
          <div className="flex justify-end pt-2">
            <Button
              kind="gradient-primary"
              size="sm"
              loading={savingLocation}
              onClick={() => void saveLocation()}
            >
              Save location
            </Button>
          </div>
        ) : null}
      </section>

      <nav aria-label="Settings sections" className="divide-y divide-border border-y border-border">
        <SettingsRow
          title="Notifications"
          meta="Quotes, order status, social, payouts"
          href="/dashboard/settings/notifications"
          testId="settings-notifications"
        />
        <SettingsRow
          title="Privacy & consent"
          meta="Consent history, capture-data retention"
          href="/dashboard/settings/privacy"
          testId="settings-privacy"
        />
        <SettingsRow
          title="Account & data"
          meta="Download my data · Delete all"
          href="/dashboard/settings/account"
          testId="settings-account-data"
        />
      </nav>

      <section aria-labelledby="settings-appearance-h" className="flex flex-col gap-3">
        <h2
          id="settings-appearance-h"
          className="pb-1 text-body font-semibold text-text-2"
        >
          Appearance & language
        </h2>
        <div className="flex items-center justify-between">
          <label htmlFor="settings-theme" className="text-body text-text">
            Theme
          </label>
          <div className="w-40">
            <Select
              aria-label="Theme"
              options={[
                { value: "system", label: "System" },
                { value: "light", label: "Light" },
                { value: "dark", label: "Dark" },
              ]}
              value={preference}
              onValueChange={(v) =>
                setPreference(v as "system" | "light" | "dark")
              }
            />
          </div>
        </div>
        <div className="flex items-center justify-between">
          <label htmlFor="settings-language" className="text-body text-text">
            Language
          </label>
          <div className="w-40">
            <Select
              aria-label="Language"
              options={[{ value: "en", label: "English" }]}
              value="en"
              onValueChange={() => {}}
            />
          </div>
        </div>
      </section>

      <section aria-label="Session">
        <Button
          kind="quiet"
          onClick={() => {
            void auth.signOut().then(() => router.replace("/signin"));
          }}
        >
          <LogOut size={20} aria-hidden /> Sign out
        </Button>
      </section>
    </div>
  );
}
