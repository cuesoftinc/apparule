import { describe, expect, it, vi } from "vitest";
import { fireEvent, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MediaDropzone, MediaUploadTile } from "./MediaDropzone";

describe("MediaDropzone (§8.2b)", () => {
  it.each(["empty", "uploading", "error"] as const)(
    "renders state=%s",
    (state) => {
      const { container } = render(
        <MediaDropzone state={state} onFiles={() => {}} />,
      );
      expect(container.querySelector(`[data-state="${state}"]`)).not.toBeNull();
    },
  );

  it("uploading shows tabular progress", () => {
    render(<MediaDropzone state="uploading" progress={0.6} onFiles={() => {}} />);
    expect(screen.getByText(/60%/)).toBeInTheDocument();
  });

  it("error state announces the size/type message", () => {
    // Figma master (94:1142): headline + type hint inside the dropzone
    render(<MediaDropzone state="error" onFiles={() => {}} />);
    expect(screen.getByRole("alert")).toHaveTextContent(/File too large/);
    expect(screen.getByText(/JPEG\/PNG\/WebP only/)).toBeInTheDocument();
  });

  it("file picks call onFiles", async () => {
    const onFiles = vi.fn();
    render(<MediaDropzone onFiles={onFiles} />);
    const file = new File(["x"], "outfit.jpg", { type: "image/jpeg" });
    await userEvent.upload(screen.getByTestId("media-input"), file);
    expect(onFiles).toHaveBeenCalledWith([file]);
  });

  it("drop calls onFiles", () => {
    const onFiles = vi.fn();
    render(<MediaDropzone onFiles={onFiles} />);
    const file = new File(["x"], "outfit.jpg", { type: "image/jpeg" });
    fireEvent.drop(screen.getByRole("button"), {
      dataTransfer: { files: [file] },
    });
    expect(onFiles).toHaveBeenCalledWith([file]);
  });
});

describe("MediaUploadTile (§8.2b)", () => {
  it("renders remove + alt-text indicator", async () => {
    const onRemove = vi.fn();
    render(
      <MediaUploadTile src="/demo/outfit-w00.jpg" onRemove={onRemove} />,
    );
    expect(screen.getByRole("button", { name: "Add alt text" })).toBeInTheDocument();
    await userEvent.click(screen.getByRole("button", { name: "Remove image" }));
    expect(onRemove).toHaveBeenCalledOnce();
  });

  it("alt indicator flips when alt text exists", () => {
    render(
      <MediaUploadTile
        src="/demo/outfit-w00.jpg"
        altText="Ankara gown"
        onRemove={() => {}}
      />,
    );
    expect(screen.getByRole("button", { name: "Edit alt text" })).toBeInTheDocument();
  });
});
