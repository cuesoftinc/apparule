"use client";

// MediaDropzone / MediaUploadTile — design.md §8.2b: dropzone state empty /
// uploading (progress) / error (size · type) · tiles ×≤10 with drag-reorder
// handle, alt-text indicator, remove. Create flow limits [Decided]: images
// only, ≤10 items, ≤10MB each, JPEG/PNG/WebP.
import { useRef } from "react";
import clsx from "clsx";
import { GripVertical, ImagePlus, Text, X } from "lucide-react";
import { Spinner } from "./Spinner";

export interface MediaDropzoneProps {
  state?: "empty" | "uploading" | "error";
  /** 0–1 while uploading. */
  progress?: number;
  errorMessage?: string;
  onFiles: (files: File[]) => void;
  disabled?: boolean;
  className?: string;
}

export function MediaDropzone({
  state = "empty",
  progress = 0,
  errorMessage = "That file is too large or not an image (JPEG/PNG/WebP, ≤10MB).",
  onFiles,
  disabled,
  className,
}: MediaDropzoneProps) {
  const inputRef = useRef<HTMLInputElement>(null);
  return (
    <div className={className} data-state={state}>
      <button
        type="button"
        disabled={disabled || state === "uploading"}
        onClick={() => inputRef.current?.click()}
        onDragOver={(e) => e.preventDefault()}
        onDrop={(e) => {
          e.preventDefault();
          onFiles([...e.dataTransfer.files]);
        }}
        className={clsx(
          "flex w-full flex-col items-center justify-center gap-2 rounded-card border-2 border-dashed p-8",
          "transition-colors duration-120 ease-standard motion-reduce:transition-none",
          state === "error" ? "border-error" : "border-border hover:border-text-2",
          "disabled:opacity-60",
        )}
      >
        {state === "uploading" ? (
          <>
            <Spinner size={28} kind="gradient" />
            <span className="text-body text-text-2 tnum">
              Uploading… {Math.round(progress * 100)}%
            </span>
          </>
        ) : (
          <>
            <ImagePlus size={24} className="text-text-2" />
            <span className="text-body text-text">
              Drag photos here or <span className="font-semibold text-link">browse</span>
            </span>
            <span className="text-micro text-text-2">
              Up to 10 images · JPEG/PNG/WebP · 10 MB each
            </span>
          </>
        )}
      </button>
      {state === "error" ? (
        <p role="alert" className="mt-1 text-micro text-error">
          {errorMessage}
        </p>
      ) : null}
      <input
        ref={inputRef}
        type="file"
        accept="image/jpeg,image/png,image/webp"
        multiple
        hidden
        data-testid="media-input"
        onChange={(e) => {
          onFiles([...(e.target.files ?? [])]);
          e.target.value = "";
        }}
      />
    </div>
  );
}

export interface MediaUploadTileProps {
  src: string;
  altText?: string;
  onRemove: () => void;
  onEditAlt?: () => void;
  className?: string;
}

/** One uploaded thumb (≤10 per post) with reorder handle + alt indicator. */
export function MediaUploadTile({
  src,
  altText,
  onRemove,
  onEditAlt,
  className,
}: MediaUploadTileProps) {
  return (
    <div
      data-testid="media-tile"
      className={clsx(
        "group relative aspect-square w-24 overflow-hidden rounded-card border border-border bg-bg-elev",
        className,
      )}
    >
      {/* eslint-disable-next-line @next/next/no-img-element -- local blob/object URLs during upload */}
      <img src={src} alt={altText ?? ""} className="size-full object-cover" />
      <span
        aria-hidden
        className="absolute left-1 top-1 grid size-5 cursor-grab place-items-center rounded-card bg-black/40 text-white"
      >
        <GripVertical size={12} />
      </span>
      <button
        type="button"
        aria-label="Remove image"
        onClick={onRemove}
        className="absolute right-1 top-1 grid size-5 place-items-center rounded-pill bg-black/40 text-white hover:bg-black/60"
      >
        <X size={12} />
      </button>
      <button
        type="button"
        onClick={onEditAlt}
        aria-label={altText ? "Edit alt text" : "Add alt text"}
        className={clsx(
          "absolute bottom-1 left-1 flex items-center gap-1 rounded-pill px-1.5 py-0.5 text-micro font-semibold",
          altText ? "bg-black/40 text-white" : "bg-warn text-on-accent",
        )}
      >
        <Text size={10} />
        ALT
      </button>
    </div>
  );
}
