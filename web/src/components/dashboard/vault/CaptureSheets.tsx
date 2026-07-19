"use client";

// B4 capture flows in sheets: options (webcam upload / manual entry,
// CaptureOptionCard) · webcam upload (photo + height → MI-12 processing
// constellation → results stagger / QC guidance) · manual entry (MI-13
// ManualMeasureRow set + unit toggle).
import { useRef, useState } from "react";
import type { MeasurementSession } from "@/models";
import { useCapture } from "@/controllers/use-capture";
import { Banner } from "@/components/ui/Banner";
import { Button } from "@/components/ui/Button";
import { CaptureOptionCard } from "@/components/ui/CaptureOptionCard";
import { CaptureResults } from "@/components/ui/CaptureResults";
import { FormRow } from "@/components/ui/FormRow";
import { Input, type MeasureUnit } from "@/components/ui/Input";
import { ManualMeasureRow } from "@/components/ui/ManualMeasureRow";
import { MeasurementCard } from "@/components/ui/MeasurementCard";
import { ProcessingConstellation } from "@/components/ui/ProcessingConstellation";
import { QCHintChip, type QcFailCode, QC_GUIDANCE } from "@/components/ui/QCHintChip";
import { Sheet } from "@/components/ui/Sheet";

export function CaptureOptionsSheet({
  open,
  onOpenChange,
  onPick,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onPick: (mode: "webcam-upload" | "manual-entry") => void;
}) {
  return (
    <Sheet open={open} onOpenChange={onOpenChange} title="Update measurements">
      <div className="grid gap-3 md:grid-cols-2">
        <CaptureOptionCard mode="webcam-upload" onClick={() => onPick("webcam-upload")} />
        <CaptureOptionCard mode="manual-entry" onClick={() => onPick("manual-entry")} />
      </div>
    </Sheet>
  );
}

const MANUAL_METRICS = [
  { name: "shoulder_width", min: 25, max: 75 },
  { name: "hip_width", min: 20, max: 70 },
  { name: "chest_girth", min: 50, max: 160 },
  { name: "waist_girth", min: 40, max: 160 },
] as const;

export function ManualEntrySheet({
  open,
  onOpenChange,
  onSave,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onSave: (
    heightCm: number,
    measurements: { name: string; value_cm: number }[],
  ) => Promise<void>;
}) {
  const [height, setHeight] = useState("168");
  const [unit, setUnit] = useState<MeasureUnit>("cm");
  const [values, setValues] = useState<Record<string, number | null>>({});
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const entered = MANUAL_METRICS.filter(
    (m) => values[m.name] !== null && values[m.name] !== undefined,
  );
  const heightCm = Number(height);
  const valid =
    Number.isFinite(heightCm) &&
    heightCm >= 100 &&
    heightCm <= 230 &&
    entered.length > 0;

  const save = async () => {
    if (!valid) return;
    setBusy(true);
    setError(null);
    try {
      await onSave(
        heightCm,
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
        <FormRow label="Your height (cm)" helper="100–230 cm" required>
          <Input
            kind="numeric"
            aria-label="Height in centimeters"
            value={height}
            onChange={(e) => setHeight(e.target.value)}
            unit={unit}
            onUnitChange={setUnit}
          />
        </FormRow>
        <fieldset className="flex flex-col gap-3">
          <legend className="sr-only">Measurements</legend>
          {MANUAL_METRICS.map((metric) => (
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
            />
          ))}
        </fieldset>
        <footer className="flex justify-end">
          <Button kind="gradient-primary" type="submit" disabled={!valid} loading={busy}>
            Save to vault
          </Button>
        </footer>
      </form>
    </Sheet>
  );
}

export function WebcamCaptureSheet({
  open,
  onOpenChange,
  onSaved,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onSaved: (session: MeasurementSession) => void;
}) {
  const capture = useCapture((session) => {
    onSaved(session);
    onOpenChange(false);
  });
  const [height, setHeight] = useState("168");
  const [unit, setUnit] = useState<MeasureUnit>("cm");
  const fileRef = useRef<HTMLInputElement>(null);
  const heightCm = Number(height);
  const heightValid =
    Number.isFinite(heightCm) && heightCm >= 100 && heightCm <= 230;

  const close = (next: boolean) => {
    if (!next) void capture.retake();
    onOpenChange(next);
  };

  return (
    <Sheet open={open} onOpenChange={close} title="Webcam capture">
      {capture.phase === "idle" ? (
        <form
          className="flex flex-col gap-4"
          onSubmit={(e) => e.preventDefault()}
        >
          <p className="text-body text-text-2">
            Stand in good light, full body head to ankles, arms slightly away
            — then upload the photo.
          </p>
          <FormRow label="Your height (cm)" helper="100–230 cm" required>
            <Input
              kind="numeric"
              aria-label="Height in centimeters"
              value={height}
              onChange={(e) => setHeight(e.target.value)}
              unit={unit}
              onUnitChange={setUnit}
            />
          </FormRow>
          <label htmlFor="capture-file" className="sr-only">
            Upload a full-body photo
          </label>
          <input
            ref={fileRef}
            id="capture-file"
            type="file"
            accept="image/jpeg,image/png,image/webp"
            className="sr-only"
            data-testid="capture-file"
            onChange={(e) => {
              const file = e.target.files?.[0];
              if (file && heightValid) void capture.upload(file, heightCm);
              e.target.value = "";
            }}
          />
          <Button
            kind="gradient-primary"
            disabled={!heightValid}
            onClick={() => fileRef.current?.click()}
          >
            Choose photo
          </Button>
        </form>
      ) : null}

      {capture.phase === "processing" ? (
        <div
          aria-busy="true"
          aria-live="polite"
          className="flex flex-col items-center gap-3 py-4"
          data-testid="capture-processing"
        >
          <ProcessingConstellation
            state="processing"
            imageSrc={capture.previewUrl ?? undefined}
          />
          <p className="text-body text-text-2">Measuring — hold on…</p>
        </div>
      ) : null}

      {capture.phase === "qc_failed" && capture.qcFailure ? (
        <div className="flex flex-col items-center gap-4 py-4">
          <ProcessingConstellation
            state="failed"
            imageSrc={capture.previewUrl ?? undefined}
          />
          {capture.qcFailure.code in QC_GUIDANCE ? (
            <QCHintChip code={capture.qcFailure.code as QcFailCode} />
          ) : null}
          <p role="alert" className="text-center text-body text-text-2">
            {capture.qcFailure.guidance}
          </p>
          <Button kind="quiet" onClick={() => void capture.retake()}>
            Retake
          </Button>
        </div>
      ) : null}

      {(capture.phase === "results" || capture.phase === "saving") &&
      capture.pending ? (
        <CaptureResults
          confidences={capture.pending.measurements.map(
            (m) => m.confidence ?? 1,
          )}
          onSave={() => void capture.save()}
          onRetake={() => void capture.retake()}
          saving={capture.phase === "saving"}
        >
          {capture.pending.measurements.map((m) => (
            <MeasurementCard
              key={m.id}
              name={m.name}
              valueCm={m.value_cm}
              source="scan"
              confidence={m.confidence}
            />
          ))}
        </CaptureResults>
      ) : null}
    </Sheet>
  );
}
