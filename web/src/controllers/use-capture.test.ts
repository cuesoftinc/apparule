// Capture controller — MI-12 processing beat, per-pose QC failure mapping
// (M-10 two-photo canon), save / retake semantics (flows/vault.md §1).
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

const front = new File(["x"], "front.jpg", { type: "image/jpeg" });
const side = new File(["x"], "side.jpg", { type: "image/jpeg" });

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
        uploadPromise = result.current.upload(front, side, 168);
      });
      expect(result.current.phase).toBe("processing");
      await act(async () => {
        await vi.advanceTimersByTimeAsync(1900);
        await uploadPromise!;
      });
      expect(result.current.phase).toBe("results");
      expect(result.current.pending?.id).toBe("sess-p");
      // both files + height rode one request with one idempotency key
      expect(createCaptureSession).toHaveBeenCalledWith(
        front,
        side,
        168,
        expect.any(String),
      );
    } finally {
      vi.useRealTimers();
    }
  });

  it("maps QC failures to code + guidance + failing pose (per-pose QC)", async () => {
    vi.useFakeTimers();
    try {
      createCaptureSession.mockRejectedValue(
        new ApiError(
          "not_side_profile",
          "Turn your right side to the camera",
          422,
          {
            guidance: "Turn your right side to the camera",
            pose: "side",
          },
        ),
      );
      const { result } = renderHook(() => useCapture(vi.fn()));
      let uploadPromise: Promise<void>;
      act(() => {
        uploadPromise = result.current.upload(front, side, 168);
      });
      await act(async () => {
        await vi.advanceTimersByTimeAsync(1900);
        await uploadPromise!;
      });
      // The failure returns to the form (the failing pose re-uploads) —
      // never a dead-end phase.
      expect(result.current.phase).toBe("idle");
      expect(result.current.qcFailure).toEqual({
        code: "not_side_profile",
        guidance: "Turn your right side to the camera",
        pose: "side",
      });
      // Re-picking the failing pose clears the error.
      act(() => result.current.clearQcFailure());
      expect(result.current.qcFailure).toBeNull();
    } finally {
      vi.useRealTimers();
    }
  });

  it("defaults an un-posed failure to the front pose", async () => {
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
        uploadPromise = result.current.upload(front, side, 168);
      });
      await act(async () => {
        await vi.advanceTimersByTimeAsync(1900);
        await uploadPromise!;
      });
      expect(result.current.qcFailure?.pose).toBe("front");
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
        uploadPromise = result.current.upload(front, side, 168);
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
        uploadPromise = result.current.upload(front, side, 168);
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
