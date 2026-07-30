"use client";

// B4 capture flows in sheets: options (photo upload / manual entry,
// CaptureOptionCard — upload-only per M-12, with the "best experience:
// guided capture on the mobile app" hint) · manual entry (MI-13
// ManualMeasureRow set + unit toggle; no height — manual sessions carry
// input_height_cm: null per flows/vault.md §2). The two-photo upload flow
// itself is a page takeover (UploadMeasurementsView, Figma 549:2), not a
// sheet. The webcam capture sheet was DELETED per M-12 (full-body webcam
// capture is rejected UX: desk-height lens, unreachable controls).
import { useState } from "react";
import { CM_PER_IN } from "@/lib/format";
import {
  MANUAL_TEMPLATES,
  type MeasurementTemplate,
} from "@/models/entities/measurement";
import { Banner } from "@/components/ui/Banner";
import { Button } from "@/components/ui/Button";
import { CaptureOptionCard } from "@/components/ui/CaptureOptionCard";
import { ManualMeasureRow } from "@/components/ui/ManualMeasureRow";
import type { MeasureUnit } from "@/components/ui/Input";
import { Sheet } from "@/components/ui/Sheet";

export function CaptureOptionsSheet({
  open,
  onOpenChange,
  onPick,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onPick: (mode: "photo-upload" | "manual-entry") => void;
}) {
  return (
    <Sheet open={open} onOpenChange={onOpenChange} title="Update measurements">
      <div className="flex flex-col gap-3">
        <div className="grid gap-3 md:grid-cols-2">
          <CaptureOptionCard
            mode="photo-upload"
            onClick={() => onPick("photo-upload")}
          />
          <CaptureOptionCard
            mode="manual-entry"
            onClick={() => onPick("manual-entry")}
          />
        </div>
        {/* pages.md B4 (M-12): the options sheet carries the app hint. */}
        <p className="text-caption text-text-2">
          Best experience: guided capture on the Apparule app.
        </p>
      </div>
    </Sheet>
  );
}

// Manual field sets are the A-10 tailor templates (flows/vault.md §2) —
// the customer's measurement_template selects women (17) or men (14);
// advisory ranges are canonical cm, "double-check" only, never a block.

/**
 * The non-blocking out-of-range advisory (flows/vault.md §2). Ranges are
 * canonical cm; the message speaks the active display unit (inches by
 * default, A-9) so it matches what the user typed.
 */
export function manualAdvisory(
  value: number | null,
  min: number,
  max: number,
  unit: MeasureUnit = "in",
): string | undefined {
  if (value === null || (value >= min && value <= max)) return undefined;
  const range =
    unit === "cm"
      ? `${min}–${max} cm`
      : `${Math.round((min / CM_PER_IN) * 10) / 10}–${Math.round((max / CM_PER_IN) * 10) / 10} in`;
  return `Double-check this one — outside the usual ${range}.`;
}

export function ManualEntrySheet({
  open,
  onOpenChange,
  onSave,
  template,
  onTemplateChange,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onSave: (measurements: { name: string; value_cm: number }[]) => Promise<void>;
  /** A-10: null interposes the one-time Women/Men chooser. */
  template: MeasurementTemplate | null;
  /** Persists the chooser pick (PATCH /me) before the rows render. */
  onTemplateChange: (template: MeasurementTemplate) => Promise<void>;
}) {
  // Inches are the default display unit (A-9); stored values stay cm.
  const [unit, setUnit] = useState<MeasureUnit>("in");
  const [values, setValues] = useState<Record<string, number | null>>({});
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const metrics = template ? MANUAL_TEMPLATES[template] : [];
  const entered = metrics.filter(
    (m) => values[m.name] !== null && values[m.name] !== undefined,
  );
  const valid = entered.length > 0;

  const pickTemplate = async (pick: MeasurementTemplate) => {
    setBusy(true);
    setError(null);
    try {
      await onTemplateChange(pick);
    } catch {
      setError("Couldn't save your choice — try again.");
    } finally {
      setBusy(false);
    }
  };

  const save = async () => {
    if (!valid) return;
    setBusy(true);
    setError(null);
    try {
      await onSave(
        entered.map((m) => ({ name: m.name, value_cm: values[m.name]! })),
      );
      setValues({});
      onOpenChange(false);
    } catch {
      setError("Couldn't save the session — try again.");
    } finally {
      setBusy(false);
    }
  };

  // A-10 one-time chooser: no template yet → pick the field set first.
  // The pick persists (PATCH /me; editable later in Settings), then the
  // sheet swaps to the template's rows in place.
  if (template === null) {
    return (
      <Sheet open={open} onOpenChange={onOpenChange} title="Enter measurements">
        <div className="flex flex-col gap-4">
          {error ? <Banner tone="error">{error}</Banner> : null}
          <p className="text-body text-text-2">
            Which measurement set fits this profile? Tailors keep different
            fields for women and men — you can change this later in Settings.
          </p>
          <div className="grid gap-3 md:grid-cols-2">
            <Button
              kind="quiet"
              disabled={busy}
              onClick={() => void pickTemplate("women")}
            >
              Women’s measurements
            </Button>
            <Button
              kind="quiet"
              disabled={busy}
              onClick={() => void pickTemplate("men")}
            >
              Men’s measurements
            </Button>
          </div>
        </div>
      </Sheet>
    );
  }

  return (
    <Sheet open={open} onOpenChange={onOpenChange} title="Enter measurements">
      <form
        className="flex flex-col gap-4"
        onSubmit={(e) => {
          e.preventDefault();
          void save();
        }}
      >
        {error ? <Banner tone="error">{error}</Banner> : null}
        <fieldset className="flex flex-col gap-3">
          <legend className="sr-only">Measurements</legend>
          {metrics.map((metric) => (
            <ManualMeasureRow
              key={metric.name}
              name={metric.name}
              valueCm={values[metric.name] ?? null}
              onChange={(value) =>
                setValues((prev) => ({ ...prev, [metric.name]: value }))
              }
              unit={unit}
              onUnitChange={setUnit}
              min={metric.min}
              max={metric.max}
              error={manualAdvisory(
                values[metric.name] ?? null,
                metric.min,
                metric.max,
                unit,
              )}
            />
          ))}
        </fieldset>
        <footer className="flex justify-end">
          <Button
            kind="gradient-primary"
            type="submit"
            disabled={!valid}
            loading={busy}
          >
            Save to vault
          </Button>
        </footer>
      </form>
    </Sheet>
  );
}
