"use client";

// B7 sub-screen — Privacy & consent: consent history (document versions +
// acceptance dates) and the capture-data retention notice (data-model §4).
import { useRouter } from "next/navigation";
import { useSettings } from "@/controllers/use-settings";
import { AppBar } from "@/components/ui/AppBar";
import { Banner } from "@/components/ui/Banner";
import { Skeleton } from "@/components/ui/Skeleton";

const DOC_LABEL: Record<string, string> = {
  tos: "Terms of Service",
  privacy: "Privacy Policy",
};

export function PrivacySettingsView() {
  const { consent, loading } = useSettings();
  const router = useRouter();

  return (
    <div className="mx-auto flex max-w-xl flex-col gap-6 px-4 pb-10">
      <AppBar
        kind="sub"
        title="Privacy & consent"
        onBack={() => router.push("/dashboard/settings")}
      />
      <h1 className="sr-only">Privacy and consent</h1>

      <Banner tone="info">
        Capture photos are retained for 30 days, then deleted automatically.
        Measurements stay in your vault until you delete them; a designer only
        ever sees the frozen snapshot inside an order you place.
      </Banner>

      <section aria-labelledby="consent-history-h">
        <h2
          id="consent-history-h"
          className="pb-2 text-body font-semibold text-text-2"
        >
          Consent history
        </h2>
        {loading ? (
          <div aria-busy="true">
            <Skeleton kind="line" />
          </div>
        ) : consent.length === 0 ? (
          <p className="text-body text-text-2">No consent records yet.</p>
        ) : (
          <ul className="divide-y divide-border" data-testid="consent-history">
            {consent.map((record) => (
              <li
                key={`${record.document}-${record.version}`}
                className="flex items-center justify-between py-3 text-body"
              >
                <span className="text-text">
                  {DOC_LABEL[record.document] ?? record.document}{" "}
                  <span className="text-text-2">v{record.version}</span>
                </span>
                <time
                  dateTime={record.accepted_at}
                  className="text-caption text-text-2"
                >
                  {new Date(record.accepted_at).toLocaleDateString("en-NG", {
                    year: "numeric",
                    month: "short",
                    day: "numeric",
                  })}
                </time>
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  );
}
