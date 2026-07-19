// Composer controller — B5 media limits, background uploads, publish gating
// with the "Outfit by {designer}" alt-text default.
import { beforeEach, describe, expect, it, vi } from "vitest";
import { act, renderHook, waitFor } from "@testing-library/react";

const uploadMedia = vi.fn();
const create = vi.fn();
const push = vi.fn();
vi.mock("@/models/repositories/posts-repo", () => ({
  postsRepo: {
    uploadMedia: (...a: unknown[]) => uploadMedia(...a),
    create: (...a: unknown[]) => create(...a),
  },
}));
vi.mock("next/navigation", () => ({
  useRouter: () => ({ push }),
}));

import { useComposer } from "./use-composer";

function imageFile(name: string, type = "image/jpeg", size = 1024): File {
  const file = new File([new ArrayBuffer(size)], name, { type });
  return file;
}

beforeEach(() => {
  uploadMedia.mockReset();
  create.mockReset();
  push.mockReset();
  URL.createObjectURL ??= () => "blob:mock";
  vi.stubGlobal(
    "URL",
    Object.assign(URL, { createObjectURL: () => "blob:mock" }),
  );
});

describe("useComposer", () => {
  it("rejects wrong types and caps at 10 images", async () => {
    uploadMedia.mockResolvedValue({ id: "med", url: "/api/mock/v1/media/med" });
    const { result } = renderHook(() => useComposer());
    act(() => result.current.addFiles([imageFile("a.gif", "image/gif")]));
    expect(result.current.media).toHaveLength(0);
    expect(result.current.dropError).toMatch(/JPEG, PNG, or WebP/);

    act(() =>
      result.current.addFiles(
        Array.from({ length: 11 }, (_, i) => imageFile(`f${i}.jpg`)),
      ),
    );
    expect(result.current.media).toHaveLength(10);
    expect(result.current.dropError).toMatch(/at most 10/);
  });

  it("publishes with uploaded urls and default alt text", async () => {
    uploadMedia.mockResolvedValue({ id: "m1", url: "/api/mock/v1/media/m1" });
    create.mockResolvedValue({ id: "post-new" });
    const { result } = renderHook(() => useComposer());
    act(() => result.current.addFiles([imageFile("look.jpg")]));
    await waitFor(() => expect(result.current.uploading).toBe(false));
    act(() =>
      result.current.setDetails({
        ...result.current.details,
        caption: "First drop",
      }),
    );
    expect(result.current.canPublish).toBe(true);
    await act(() => result.current.publish("Kiki Studio"));
    expect(create).toHaveBeenCalledWith(
      expect.objectContaining({
        caption: "First drop",
        media: [
          expect.objectContaining({
            url: "/api/mock/v1/media/m1",
            alt_text: "Outfit by Kiki Studio",
          }),
        ],
      }),
    );
    expect(push).toHaveBeenCalledWith("/dashboard");
  });

  it("blocks publish while uploads are pending or caption empty", async () => {
    let resolveUpload: (v: { id: string; url: string }) => void;
    uploadMedia.mockReturnValue(
      new Promise((resolve) => {
        resolveUpload = resolve;
      }),
    );
    const { result } = renderHook(() => useComposer());
    act(() => result.current.addFiles([imageFile("slow.jpg")]));
    act(() =>
      result.current.setDetails({
        ...result.current.details,
        caption: "Caption",
      }),
    );
    expect(result.current.uploading).toBe(true);
    expect(result.current.canPublish).toBe(false);
    await act(async () => {
      resolveUpload!({ id: "m", url: "/u" });
      await Promise.resolve();
    });
    await waitFor(() => expect(result.current.canPublish).toBe(true));
  });
});
