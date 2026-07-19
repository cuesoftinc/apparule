"use client";

// Webcam-capture controller (B4 "Retake" → webcam upload, MI-12): picks a
// photo + height, uploads to the capture endpoint, and holds the mock's
// instant answer behind a processing beat (the AFTER_TIMEOUT-style async
// verification state, design.md §8.4) before showing results. QC failures
// surface the capture-qc.md code + guidance. Save flips pending_save →
// complete; Retake purges the session (flows/vault.md §1).
import { useCallback, useRef, useState } from "react";
import type { MeasurementSession } from "@/models";
import { ApiError } from "@/lib/api";
import { vaultRepo } from "@/models/repositories/vault-repo";

/** Processing beat so the constellation reads as "AI working" (MI-12). */
const PROCESSING_MS = 1800;

export type CapturePhase =
  | "idle"
  | "processing"
  | "results"
  | "qc_failed"
  | "saving";

export interface QcFailure {
  code: string;
  guidance: string;
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

  const upload = useCallback(async (image: File, heightCm: number) => {
    // New idempotency key per capture attempt (flows/vault.md upload row).
    keyRef.current = crypto.randomUUID();
    setQcFailure(null);
    setPhase("processing");
    setPreviewUrl(URL.createObjectURL(image));
    const [outcome] = await Promise.allSettled([
      vaultRepo.createCaptureSession(image, heightCm, keyRef.current),
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
          }
        : { code: "pipeline_busy", guidance: "Something went wrong — retry." },
    );
    setPhase("qc_failed");
  }, []);

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

  return { phase, pending, qcFailure, previewUrl, upload, save, retake };
}
