"use client";

// Upload-capture controller (B4 "Retake" → photo upload, M-12 upload-only):
// two files — front + side (right profile) — plus height (M-10) upload to
// the capture endpoint; the mock's instant answer holds behind a processing
// beat (the AFTER_TIMEOUT-style async verification state, design.md §8.4)
// before showing results. QC failures surface the capture-qc.md code +
// guidance PER POSE (the 422 envelope names the failing pose): the client
// clears that pose's file only — an accepted pose is never discarded, and a
// retry never advances a pose counter (flows/vault.md §1). Save flips
// pending_save → complete; Retake purges the session.
import { useCallback, useRef, useState } from "react";
import type { MeasurementSession } from "@/models";
import { ApiError } from "@/lib/api";
import { vaultRepo } from "@/models/repositories/vault-repo";

/** Processing beat so the constellation reads as "AI working" (MI-12). */
const PROCESSING_MS = 1800;

export type CapturePose = "front" | "side";

export type CapturePhase = "idle" | "processing" | "results" | "saving";

export interface QcFailure {
  code: string;
  guidance: string;
  /** capture-qc.md §2: QC reports per pose — the failing pose re-uploads. */
  pose: CapturePose;
}

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export function useCapture(onSaved: (session: MeasurementSession) => void) {
  const [phase, setPhase] = useState<CapturePhase>("idle");
  const [pending, setPending] = useState<MeasurementSession | null>(null);
  const [qcFailure, setQcFailure] = useState<QcFailure | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const keyRef = useRef<string>("");

  const upload = useCallback(
    async (imageFront: File, imageSide: File, heightCm: number) => {
      // New idempotency key per capture attempt (flows/vault.md upload row:
      // both images ride one request with one key).
      keyRef.current = crypto.randomUUID();
      setQcFailure(null);
      setPhase("processing");
      setPreviewUrl(URL.createObjectURL(imageFront));
      const [outcome] = await Promise.allSettled([
        vaultRepo.createCaptureSession(
          imageFront,
          imageSide,
          heightCm,
          keyRef.current,
        ),
        delay(PROCESSING_MS),
      ]);
      // Both settle together; the delay only paces the constellation.
      await delay(0);
      if (outcome.status === "fulfilled") {
        setPending(outcome.value);
        setPhase("results");
        return;
      }
      const e = outcome.reason;
      setQcFailure(
        e instanceof ApiError
          ? {
              code: e.code,
              guidance: (e.details?.guidance as string) ?? e.message,
              pose: e.details?.pose === "side" ? "side" : "front",
            }
          : {
              code: "pipeline_busy",
              guidance: "Something went wrong — retry.",
              pose: "front",
            },
      );
      // QC failure returns to the form: the failing pose's dropzone renders
      // the error state and the user re-picks that pose's file only.
      setPhase("idle");
      setPreviewUrl(null);
    },
    [],
  );

  const save = useCallback(async () => {
    if (!pending) return;
    setPhase("saving");
    try {
      const saved = await vaultRepo.saveSession(pending.id);
      setPending(null);
      setPhase("idle");
      setPreviewUrl(null);
      onSaved(saved);
    } catch {
      setPhase("results");
    }
  }, [pending, onSaved]);

  /** Retake discards the pending session immediately (flows/vault.md). */
  const retake = useCallback(async () => {
    const stale = pending;
    setPending(null);
    setQcFailure(null);
    setPhase("idle");
    setPreviewUrl(null);
    if (stale) {
      await vaultRepo.deleteSession(stale.id).catch(() => {
        // pending sessions auto-purge server-side after 24h anyway
      });
    }
  }, [pending]);

  /** The failing pose was re-picked — clear the stale QC error. */
  const clearQcFailure = useCallback(() => setQcFailure(null), []);

  return {
    phase,
    pending,
    qcFailure,
    previewUrl,
    upload,
    save,
    retake,
    clearQcFailure,
  };
}
