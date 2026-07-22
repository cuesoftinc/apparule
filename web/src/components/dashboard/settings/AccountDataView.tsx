"use client";

// B7 sub-screen — Account & data: export (Download my data) and delete-all
// with confirm — the B4 rights links resolve here (data-model §4 parity).
// Danger ladder [Decided 2026-07-22]: the row-level "Delete all" renders
// quiet-danger; the armed confirm sheet carries the typed-DELETE gate, the
// "Export everything first" escape hatch, and Cancel (design.md §8.2;
// mobile sibling account_data_screen.dart).
import { useState } from "react";
import { useRouter } from "next/navigation";
import { useSettings } from "@/controllers/use-settings";
import { AppBar } from "@/components/ui/AppBar";
import { Banner } from "@/components/ui/Banner";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { Sheet } from "@/components/ui/Sheet";
import { useToasts } from "../toast-context";

export function AccountDataView() {
  const settings = useSettings();
  const router = useRouter();
  const { showToast } = useToasts();
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [confirmText, setConfirmText] = useState("");
  const armed = confirmText.trim() === "DELETE";
  const closeConfirm = (open: boolean) => {
    setConfirmOpen(open);
    if (!open) setConfirmText("");
  };

  const download = async () => {
    try {
      const url = await settings.exportData();
      const anchor = document.createElement("a");
      anchor.href = url;
      anchor.download = "apparule-export.json";
      anchor.click();
      URL.revokeObjectURL(url);
      showToast({ kind: "success", message: "Export downloaded" });
    } catch {
      showToast({ kind: "error", message: "Export failed — try again" });
    }
  };

  const requestDeletion = async () => {
    try {
      await settings.requestDeletion();
      closeConfirm(false);
      showToast({ kind: "neutral", message: "Deletion requested" });
    } catch {
      showToast({ kind: "error", message: "Couldn't request deletion" });
    }
  };

  return (
    <div className="mx-auto flex max-w-xl flex-col gap-6 px-4 pb-10">
      <AppBar
        kind="sub"
        title="Account & data"
        onBack={() => router.push("/dashboard/settings")}
      />
      <h1 className="sr-only">Account and data</h1>

      {settings.account?.deletion_state === "deletion_pending" ? (
        <Banner tone="warn">
          Deletion requested — your account and data will be removed after the
          grace period. Contact support to cancel.
        </Banner>
      ) : null}

      <section aria-labelledby="export-h" className="flex flex-col gap-2">
        <h2 id="export-h" className="text-body font-semibold text-text-2">
          Download my data
        </h2>
        <p className="text-body text-text-2">
          A JSON export of your account, measurement sessions, orders, saved
          looks, and consent records.
        </p>
        <div>
          <Button
            kind="quiet"
            loading={settings.exporting}
            onClick={() => void download()}
            data-testid="export-data"
          >
            Download export
          </Button>
        </div>
      </section>

      <section aria-labelledby="delete-h" className="flex flex-col gap-2">
        <h2 id="delete-h" className="text-body font-semibold text-text-2">
          Delete all my data
        </h2>
        <p className="text-body text-text-2">
          Removes your measurements, posts, and profile after a 30-day grace
          period. Open orders finish first; this can&apos;t be undone after the
          grace period.
        </p>
        <div>
          {/* Row rung: quiet-danger — filled destructive is reserved for
              the armed confirm below (danger ladder). */}
          <Button
            kind="quiet-danger"
            disabled={settings.account?.deletion_state === "deletion_pending"}
            onClick={() => setConfirmOpen(true)}
            data-testid="delete-all"
          >
            Delete all
          </Button>
        </div>
      </section>

      <Sheet
        open={confirmOpen}
        onOpenChange={closeConfirm}
        title="Delete everything?"
      >
        <div className="flex flex-col gap-4">
          <p className="text-body text-text-2">
            This requests permanent deletion of your account and vault. You have
            30 days to change your mind.
          </p>
          {/* Armed rung: the typed token gates the filled confirm. */}
          <div className="flex flex-col gap-2">
            <label
              htmlFor="delete-confirm-input"
              className="text-body font-semibold text-text"
            >
              Type DELETE to confirm
            </label>
            <Input
              id="delete-confirm-input"
              value={confirmText}
              onChange={(e) => setConfirmText(e.target.value)}
              placeholder="DELETE"
              autoComplete="off"
              data-testid="delete-confirm-input"
            />
          </div>
          {/* Escape hatch: export before deleting (data-model §4 rights). */}
          <div>
            <Button
              kind="link"
              loading={settings.exporting}
              onClick={() => void download()}
              data-testid="export-first"
            >
              Export everything first
            </Button>
          </div>
          <footer className="flex justify-end gap-2">
            <Button kind="quiet" onClick={() => closeConfirm(false)}>
              Cancel
            </Button>
            <Button
              kind="destructive"
              disabled={!armed}
              loading={settings.deleting}
              onClick={() => void requestDeletion()}
              data-testid="confirm-delete-all"
            >
              Delete all
            </Button>
          </footer>
        </div>
      </Sheet>
    </div>
  );
}
