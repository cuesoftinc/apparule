// Capture controller — MI-12 processing beat, QC failure mapping, save /
// retake semantics (flows/vault.md §1).
import { beforeEach, describe, expect, it, vi } from "vitest";
import { act, renderHook } from "@testing-library/react";
import { ApiError } from "@/lib/api";

const createCaptureSession = vi.fn();
const saveSession = vi.fn();
const deleteSession = vi.fn();
vi.mock("@/models/repositories/vault-repo", () => ({
  vaultRepo: {
    createCaptureSession: (...a: unknown[]) => createCaptureSession(...a),
    saveSession: (...a: unknown[]) => saveSession(...a),
    deleteSession: (...a: unknown[]) => deleteSession(...a),
  },
}));

import { useCapture } from "./use-capture";

const pendingSession = {
  id: "sess-p",
  customer_id: "acc-kiki",
  method: "mediapipe_2d_v2",
  input_height_cm: 168,
  status: "pending_save",
  measurements: [],
  pipeline_meta: {},
  created_at: new Date().toISOString(),
};

const file = new File(["x"], "photo.jpg", { type: "image/jpeg" });

beforeEach(() => {
  createCaptureSession.mockReset();
  saveSession.mockReset();
  deleteSession.mockReset();
  // jsdom lacks createObjectURL
  URL.createObjectURL ??= () => "blob:mock";
  vi.stubGlobal(
    "URL",
    Object.assign(URL, { createObjectURL: () => "blob:mock" }),
  );
});

describe("useCapture", () => {
  it("paces the mock's instant answer behind the processing beat", async () => {
    vi.useFakeTimers();
    try {
      createCaptureSession.mockResolvedValue(pendingSession);
      const onSaved = vi.fn();
      const { result } = renderHook(() => useCapture(onSaved));
      let uploadPromise: Promise<void>;
      act(() => {
        uploadPromise = result.current.upload(file, 168);
      });
      expect(result.current.phase).toBe("processing");
      await act(async () => {
        await vi.advanceTimersByTimeAsync(1900);
        await uploadPromise!;
      });
      expect(result.current.phase).toBe("results");
      expect(result.current.pending?.id).toBe("sess-p");
    } finally {
      vi.useRealTimers();
    }
  });

  it("maps QC failures to code + guidance", async () => {
    vi.useFakeTimers();
    try {
      createCaptureSession.mockRejectedValue(
        new ApiError("blurry", "Hold steady and retake", 422, {
          guidance: "Hold steady and retake",
        }),
      );
      const { result } = renderHook(() => useCapture(vi.fn()));
      let uploadPromise: Promise<void>;
      act(() => {
        uploadPromise = result.current.upload(file, 168);
      });
      await act(async () => {
        await vi.advanceTimersByTimeAsync(1900);
        await uploadPromise!;
      });
      expect(result.current.phase).toBe("qc_failed");
      expect(result.current.qcFailure).toEqual({
        code: "blurry",
        guidance: "Hold steady and retake",
      });
    } finally {
      vi.useRealTimers();
    }
  });

  it("save completes the pending session; retake purges it", async () => {
    vi.useFakeTimers();
    try {
      createCaptureSession.mockResolvedValue(pendingSession);
      saveSession.mockResolvedValue({ ...pendingSession, status: "complete" });
      deleteSession.mockResolvedValue(undefined);
      const onSaved = vi.fn();
      const { result } = renderHook(() => useCapture(onSaved));
      let uploadPromise: Promise<void>;
      act(() => {
        uploadPromise = result.current.upload(file, 168);
      });
      await act(async () => {
        await vi.advanceTimersByTimeAsync(1900);
        await uploadPromise!;
      });
      await act(() => result.current.save());
      expect(onSaved).toHaveBeenCalledWith(
        expect.objectContaining({ status: "complete" }),
      );
      expect(result.current.phase).toBe("idle");

      // retake path
      act(() => {
        uploadPromise = result.current.upload(file, 168);
      });
      await act(async () => {
        await vi.advanceTimersByTimeAsync(1900);
        await uploadPromise!;
      });
      await act(() => result.current.retake());
      expect(deleteSession).toHaveBeenCalledWith("sess-p");
      expect(result.current.phase).toBe("idle");
    } finally {
      vi.useRealTimers();
    }
  });
});
