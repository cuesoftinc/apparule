"use client";

// B4 — Upload measurements (Figma 549:2; M-10 two-photo canon + M-12
// upload-only): labeled Front/Side dropzones with per-pose states (empty /
// uploaded thumbnail + Replace / QC-error + QCHintChip), a Height FormRow
// with the MI-13 cm/in toggle — inches active by default (A-9), entry
// converts to canonical cm before the repository (the payload stays
// `user_height_cm`, 100–230; prefilled from the latest capture session —
// never a fabricated default), the "Get measurements" CTA into the MI-12
// processing constellation, and the results stagger → Save to vault. A QC failure
// re-opens only the failing pose (per-pose QC, capture-qc.md §2) — the
// accepted pose's file is kept. Renders as a page takeover of the vault
// content (in-content left-aligned h1 — the IG-desktop idiom, M-9 scope).
import { useRef, useState } from "react";
import clsx from "clsx";
import { AlertTriangle, Camera, ChevronLeft } from "lucide-react";
import type { MeasurementSession } from "@/models";
import { useCapture, type CapturePose } from "@/controllers/use-capture";
import { Button } from "@/components/ui/Button";
import { CaptureResults } from "@/components/ui/CaptureResults";
import { CM_PER_IN } from "@/lib/format";
import { FormRow } from "@/components/ui/FormRow";
import { Input, type MeasureUnit } from "@/components/ui/Input";
import { MeasurementCard } from "@/components/ui/MeasurementCard";
import { ProcessingConstellation } from "@/components/ui/ProcessingConstellation";
import {
  QCHintChip,
  QC_GUIDANCE,
  type QcFailCode,
} from "@/components/ui/QCHintChip";

/** flows/vault.md upload row: each image ≤ 10 MB, JPEG/PNG/HEIC. */
const MAX_IMAGE_BYTES = 10 * 1024 * 1024;
const ACCEPT = "image/jpeg,image/png,image/heic";

const POSE_LABEL: Record<CapturePose, string> = {
  front: "Front photo",
  side: "Side photo",
};

/** Canonical cm → the height field's display string in the active unit
 * (1-decimal rounding, the MI-13 conversion canon). */
const heightDisplay = (cm: number, unit: MeasureUnit) =>
  String(Math.round((unit === "cm" ? cm : cm / CM_PER_IN) * 10) / 10);

/** flows/vault.md §1 height contract: 100–230 cm (39–91 in). */
const HEIGHT_RANGE: Record<MeasureUnit, string> = {
  cm: "100–230 cm",
  in: "39–91 in",
};

const HEIGHT_UNIT_WORD: Record<MeasureUnit, string> = {
  cm: "centimeters",
  in: "inches",
};

interface PickedImage {
  file: File;
  previewUrl: string;
}

function PoseDropzone({
  pose,
  picked,
  qcCode,
  localError,
  onFile,
}: {
  pose: CapturePose;
  picked: PickedImage | null;
  /** capture-qc.md code when this pose failed QC (error state). */
  qcCode: string | null;
  localError: string | null;
  onFile: (file: File) => void;
}) {
  const inputRef = useRef<HTMLInputElement>(null);
  const pick = () => inputRef.current?.click();
  const knownCode =
    qcCode && qcCode in QC_GUIDANCE ? (qcCode as QcFailCode) : null;

  return (
    <div className="flex flex-col gap-2" data-pose={pose}>
      <span
        id={`pose-label-${pose}`}
        className="text-body font-semibold text-text"
      >
        {POSE_LABEL[pose]}
      </span>

      {qcCode ? (
        // Figma 549:2 side-pose exemplar: dashed error dropzone + hint chip.
        <button
          type="button"
          aria-labelledby={`pose-label-${pose}`}
          onClick={pick}
          onDragOver={(e) => e.preventDefault()}
          onDrop={(e) => {
            e.preventDefault();
            const file = e.dataTransfer.files[0];
            if (file) onFile(file);
          }}
          data-testid={`pose-error-${pose}`}
          className="flex aspect-[4/3] w-full flex-col items-center justify-center gap-2 rounded-card border-2 border-dashed border-error p-6"
        >
          <AlertTriangle size={24} className="text-error" />
          <span role="alert" className="text-body font-semibold text-error">
            Quality check failed
          </span>
          <span className="text-micro text-text-2">
            Follow the hint below, then re-upload this pose
          </span>
        </button>
      ) : picked ? (
        <div className="flex flex-col gap-2">
          <div className="relative aspect-[4/3] w-full overflow-hidden rounded-card border border-border bg-bg-elev">
            {/* eslint-disable-next-line @next/next/no-img-element -- local object URL preview */}
            <img
              src={picked.previewUrl}
              alt={`${POSE_LABEL[pose]} preview`}
              className="size-full object-cover"
            />
          </div>
          <p className="text-caption text-text-2">
            {picked.file.name} · uploaded{" "}
            <button
              type="button"
              onClick={pick}
              className="pl-2 font-semibold text-link underline underline-offset-2"
            >
              Replace
            </button>
          </p>
        </div>
      ) : (
        <button
          type="button"
          aria-labelledby={`pose-label-${pose}`}
          onClick={pick}
          onDragOver={(e) => e.preventDefault()}
          onDrop={(e) => {
            e.preventDefault();
            const file = e.dataTransfer.files[0];
            if (file) onFile(file);
          }}
          className={clsx(
            "flex aspect-[4/3] w-full flex-col items-center justify-center gap-2 rounded-card border-2 border-dashed border-border p-6",
            "transition-colors duration-120 ease-standard hover:border-text-2 motion-reduce:transition-none",
          )}
        >
          <Camera size={24} className="text-text-2" />
          <span className="text-body text-text">
            Drag a photo here or{" "}
            <span className="font-semibold text-link">browse</span>
          </span>
          <span className="text-micro text-text-2">JPEG/PNG/HEIC · 10 MB</span>
        </button>
      )}

      {knownCode ? <QCHintChip code={knownCode} pose={pose} /> : null}
      {localError ? (
        <p role="alert" className="text-micro text-error">
          {localError}
        </p>
      ) : null}

      <input
        ref={inputRef}
        type="file"
        accept={ACCEPT}
        hidden
        data-testid={`capture-file-${pose}`}
        onChange={(e) => {
          const file = e.target.files?.[0];
          if (file) onFile(file);
          e.target.value = "";
        }}
      />
    </div>
  );
}

export interface UploadMeasurementsViewProps {
  /**
   * Latest capture session's `input_height_cm` — the web analogue of
   * mobile's height prefill. Null when there is none (no fabricated
   * default; manual sessions carry no height).
   */
  prefillHeightCm: number | null;
  onBack: () => void;
  onSaved: (session: MeasurementSession) => void;
}

export function UploadMeasurementsView({
  prefillHeightCm,
  onBack,
  onSaved,
}: UploadMeasurementsViewProps) {
  const capture = useCapture(onSaved);
  const [images, setImages] = useState<Record<CapturePose, PickedImage | null>>(
    { front: null, side: null },
  );
  const [localErrors, setLocalErrors] = useState<
    Record<CapturePose, string | null>
  >({ front: null, side: null });
  // Height rides in canonical cm; the field displays the active unit —
  // inches by default (A-9). Keeping the cm number alongside the text means
  // a prefilled 168 survives unit flips and submits as exactly 168 (the
  // 1-decimal inch display never round-trips drift into the payload).
  const [heightUnit, setHeightUnit] = useState<MeasureUnit>("in");
  const [heightCm, setHeightCm] = useState<number | null>(prefillHeightCm);
  const [height, setHeight] = useState(
    prefillHeightCm === null ? "" : heightDisplay(prefillHeightCm, "in"),
  );

  const editHeight = (raw: string) => {
    setHeight(raw);
    if (raw.trim() === "") {
      setHeightCm(null);
      return;
    }
    const num = Number(raw);
    setHeightCm(
      Number.isFinite(num)
        ? heightUnit === "cm"
          ? num
          : num * CM_PER_IN
        : Number.NaN,
    );
  };

  const switchHeightUnit = (next: MeasureUnit) => {
    setHeightUnit(next);
    // Re-render the entered value in the new unit — same physical height.
    if (heightCm !== null && Number.isFinite(heightCm)) {
      setHeight(heightDisplay(heightCm, next));
    }
  };

  const heightValid =
    heightCm !== null &&
    Number.isFinite(heightCm) &&
    heightCm >= 100 &&
    heightCm <= 230;

  const pickFile = (pose: CapturePose, file: File) => {
    if (file.size > MAX_IMAGE_BYTES) {
      setLocalErrors((prev) => ({
        ...prev,
        [pose]: "That photo is over 10 MB — try a smaller one.",
      }));
      return;
    }
    setLocalErrors((prev) => ({ ...prev, [pose]: null }));
    setImages((prev) => {
      const stale = prev[pose];
      if (stale) URL.revokeObjectURL(stale.previewUrl);
      return {
        ...prev,
        [pose]: { file, previewUrl: URL.createObjectURL(file) },
      };
    });
    // Re-picking the failing pose clears its QC error (the retry re-enters
    // this pose only — the pose counter never advances, flows/vault.md §1).
    if (capture.qcFailure?.pose === pose) capture.clearQcFailure();
  };

  const canSubmit =
    images.front !== null &&
    images.side !== null &&
    heightValid &&
    capture.qcFailure === null;

  const submit = () => {
    if (!images.front || !images.side || heightCm === null || !heightValid) {
      return;
    }
    // The payload stays canonical cm (`user_height_cm`) whatever the
    // display unit — conversion happened at input time.
    void capture.upload(images.front.file, images.side.file, heightCm);
  };

  const retake = () => {
    void capture.retake();
    setImages((prev) => {
      for (const picked of Object.values(prev)) {
        if (picked) URL.revokeObjectURL(picked.previewUrl);
      }
      return { front: null, side: null };
    });
  };

  // A QC failure discards only the failing pose's file — render that pose's
  // dropzone in its error state (the accepted pose keeps its thumbnail).
  const qcPose = capture.qcFailure?.pose ?? null;

  return (
    <div
      className="mx-auto flex max-w-2xl flex-col gap-6 px-4 py-6"
      data-testid="upload-measurements"
    >
      <div>
        <Button kind="link" onClick={onBack} className="-ml-1">
          <ChevronLeft size={16} aria-hidden />
          Back to vault
        </Button>
      </div>

      {capture.phase === "processing" ? (
        <div
          aria-busy="true"
          aria-live="polite"
          className="flex flex-col items-center gap-3 py-10"
          data-testid="capture-processing"
        >
          <ProcessingConstellation
            state="processing"
            imageSrc={capture.previewUrl ?? undefined}
          />
          <p className="text-body text-text-2">Measuring — hold on…</p>
        </div>
      ) : capture.phase === "results" || capture.phase === "saving" ? (
        capture.pending ? (
          <CaptureResults
            confidences={capture.pending.measurements.map(
              (m) => m.confidence ?? 1,
            )}
            onSave={() => void capture.save()}
            onRetake={retake}
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
        ) : null
      ) : (
        <form
          className="flex flex-col gap-6"
          onSubmit={(e) => {
            e.preventDefault();
            submit();
          }}
        >
          {/* Figma 549:2 header block — in-content, left-aligned. */}
          <header className="flex flex-col gap-1">
            <h1 className="text-title-lg font-bold text-text">
              Upload measurements
            </h1>
            <p className="text-body text-text-2">
              Two photos — front and side — plus your height. We map 33
              landmarks per photo.
            </p>
            <p className="text-caption text-text-2">
              Best experience: guided capture on the Apparule app
            </p>
          </header>

          <div className="grid gap-6 md:grid-cols-2">
            <PoseDropzone
              pose="front"
              picked={qcPose === "front" ? null : images.front}
              qcCode={qcPose === "front" ? capture.qcFailure!.code : null}
              localError={localErrors.front}
              onFile={(file) => pickFile("front", file)}
            />
            <PoseDropzone
              pose="side"
              picked={qcPose === "side" ? null : images.side}
              qcCode={qcPose === "side" ? capture.qcFailure!.code : null}
              localError={localErrors.side}
              onFile={(file) => pickFile("side", file)}
            />
          </div>

          <FormRow
            label={`Height (${heightUnit})`}
            helper={`Used to scale your photos — ${HEIGHT_RANGE[heightUnit]}`}
            required
            className="max-w-xs"
          >
            <Input
              kind="numeric"
              aria-label={`Height in ${HEIGHT_UNIT_WORD[heightUnit]}`}
              value={height}
              onChange={(e) => editHeight(e.target.value)}
              unit={heightUnit}
              onUnitChange={switchHeightUnit}
            />
          </FormRow>

          <div>
            <Button
              kind="gradient-primary"
              type="submit"
              disabled={!canSubmit}
              data-testid="get-measurements"
            >
              Get measurements
            </Button>
          </div>
        </form>
      )}
    </div>
  );
}
