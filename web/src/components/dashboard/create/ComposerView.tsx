"use client";

// B5 — Post an outfit: dropzone (≤10 images, reorder, alt text) → details
// (caption · style tags · base price or quote-on-request · turnaround ·
// fabric notes in caption) → publish → feed. Non-creators see the
// become-a-designer upsell; pre-KYC creators can post but see the A-2
// requests gate (flows/designer.md §1). Render-only over useComposer.
import { useState, type FormEvent } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useAuth } from "@/auth/AuthContext";
import { useComposer } from "@/controllers/use-composer";
import { Banner } from "@/components/ui/Banner";
import { Button } from "@/components/ui/Button";
import { Chip } from "@/components/ui/Chip";
import { FormRow } from "@/components/ui/FormRow";
import { Input } from "@/components/ui/Input";
import { MediaDropzone, MediaUploadTile } from "@/components/ui/MediaDropzone";
import { useToasts } from "../toast-context";

export function ComposerView() {
  const { account } = useAuth();
  const router = useRouter();
  const composer = useComposer();
  const { showToast } = useToasts();
  const [tagDraft, setTagDraft] = useState("");

  // Creator-profile upsell for non-designers (pages.md B5).
  if (account && !account.designer.enabled) {
    return (
      <div className="mx-auto flex max-w-xl flex-col gap-4 px-4 py-16 text-center">
        <h1 className="text-title-lg font-bold text-text">
          Post outfits, get commissioned, get paid
        </h1>
        <p className="text-body text-text-2">
          Turn your work into a storefront: publish looks, receive requests with
          exact measurements attached, and get paid through escrow.
        </p>
        <div>
          <Link
            href="/dashboard/designer/onboarding"
            data-testid="become-designer"
            className="inline-flex h-11 items-center justify-center rounded-card bg-accent-gradient px-6 text-body font-semibold text-on-accent"
          >
            Become a designer
          </Link>
        </div>
      </div>
    );
  }

  const kycPending =
    account?.designer.enabled && !account.designer.kyc_complete;

  const addTag = (e: FormEvent) => {
    e.preventDefault();
    const tag = tagDraft.trim().toLowerCase().replace(/^#/, "");
    if (tag && !composer.details.styleTags.includes(tag)) {
      composer.setDetails({
        ...composer.details,
        styleTags: [...composer.details.styleTags, tag],
      });
    }
    setTagDraft("");
  };

  const publish = async () => {
    const post = await composer.publish(account?.display_name ?? "designer");
    if (post) {
      showToast({ kind: "success", message: "Outfit published" });
    }
  };

  return (
    <div className="mx-auto flex max-w-xl flex-col gap-6 px-4 py-6">
      <header>
        <h1 className="text-title-lg font-bold text-text">Post an outfit</h1>
      </header>

      {kycPending ? (
        <Banner
          tone="warn"
          actionLabel="Finish verification"
          onAction={() => router.push("/dashboard/designer/onboarding")}
        >
          You can publish now, but posts won&apos;t accept requests until your
          payout account is verified.
        </Banner>
      ) : null}

      {composer.publishError ? (
        <Banner tone="error">{composer.publishError}</Banner>
      ) : null}

      <section
        aria-labelledby="composer-media-h"
        className="flex flex-col gap-3"
      >
        <h2
          id="composer-media-h"
          className="text-body font-semibold text-text-2"
        >
          Photos ({composer.media.length}/10)
        </h2>
        {composer.media.length < 10 ? (
          <MediaDropzone
            onFiles={(files) => composer.addFiles(files)}
            state={composer.dropError ? "error" : "empty"}
            errorMessage={composer.dropError ?? undefined}
          />
        ) : null}
        {composer.media.length > 0 ? (
          <ul className="flex flex-wrap gap-2" data-testid="composer-tiles">
            {composer.media.map((item, index) => (
              <li key={item.localId} className="flex w-40 flex-col gap-1">
                <div className="relative">
                  <MediaUploadTile
                    src={item.previewUrl}
                    altText={item.altText || undefined}
                    onRemove={() => composer.removeItem(item.localId)}
                    className="w-40"
                  />
                  {item.url === null && item.error === null ? (
                    <span className="absolute inset-x-0 bottom-0 bg-black/50 py-0.5 text-center text-micro text-white">
                      Uploading…
                    </span>
                  ) : null}
                  {item.error ? (
                    <span
                      role="alert"
                      className="absolute inset-x-0 bottom-0 bg-error py-0.5 text-center text-micro text-on-accent"
                    >
                      {item.error}
                    </span>
                  ) : null}
                </div>
                <div className="flex items-center justify-between">
                  <Button
                    kind="quiet"
                    size="sm"
                    aria-label={`Move image ${index + 1} earlier`}
                    disabled={index === 0}
                    onClick={() => composer.moveItem(item.localId, -1)}
                  >
                    ←
                  </Button>
                  <span className="text-micro text-text-2">{index + 1}</span>
                  <Button
                    kind="quiet"
                    size="sm"
                    aria-label={`Move image ${index + 1} later`}
                    disabled={index === composer.media.length - 1}
                    onClick={() => composer.moveItem(item.localId, 1)}
                  >
                    →
                  </Button>
                </div>
                <label className="sr-only" htmlFor={`alt-${item.localId}`}>
                  Alt text for image {index + 1}
                </label>
                <Input
                  id={`alt-${item.localId}`}
                  placeholder="Describe this image"
                  value={item.altText}
                  onChange={(e) =>
                    composer.setAltText(item.localId, e.target.value)
                  }
                />
              </li>
            ))}
          </ul>
        ) : (
          /* B5 frame (180:827): the media area carries no EmptyState — the
             explore-context EmptyState rendered a search icon + "Clear
             search" CTA on the create screen (wrong-context bug, audit §3). */
          <p className="text-caption text-text-2">
            Add up to 10 photos — JPEG, PNG, or WebP, 10 MB max.
          </p>
        )}
      </section>

      <form
        className="flex flex-col gap-4"
        onSubmit={(e) => {
          e.preventDefault();
          void publish();
        }}
      >
        <FormRow label="Caption" required>
          <Input
            kind="textarea"
            aria-label="Caption"
            placeholder="Tell customers about the piece — fabric, fit, occasion…"
            maxLength={500}
            value={composer.details.caption}
            onChange={(e) =>
              composer.setDetails({
                ...composer.details,
                caption: e.target.value,
              })
            }
          />
        </FormRow>

        <FormRow label="Style tags" helper="Press Enter to add">
          <div className="flex flex-col gap-2">
            <Input
              aria-label="Add a style tag"
              placeholder="ankara, agbada, wedding…"
              value={tagDraft}
              onChange={(e) => setTagDraft(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter") addTag(e);
              }}
            />
            {composer.details.styleTags.length > 0 ? (
              <ul className="flex flex-wrap gap-2">
                {composer.details.styleTags.map((tag) => (
                  <li key={tag}>
                    <Chip
                      kind="removable"
                      label={tag}
                      onRemove={() =>
                        composer.setDetails({
                          ...composer.details,
                          styleTags: composer.details.styleTags.filter(
                            (t) => t !== tag,
                          ),
                        })
                      }
                    />
                  </li>
                ))}
              </ul>
            ) : null}
          </div>
        </FormRow>

        <FormRow label="Base price" helper="Leave empty for “quote on request”">
          <Input
            kind="currency"
            aria-label="Base price"
            placeholder="45,000"
            value={
              composer.details.basePriceCents !== null
                ? String(composer.details.basePriceCents / 100)
                : ""
            }
            onChange={(e) => {
              const parsed = Number(e.target.value.replace(/[^\d.]/g, ""));
              composer.setDetails({
                ...composer.details,
                basePriceCents:
                  Number.isFinite(parsed) && e.target.value !== ""
                    ? Math.round(parsed * 100)
                    : null,
              });
            }}
          />
        </FormRow>

        <FormRow label="Turnaround (days)" required>
          <Input
            kind="numeric"
            aria-label="Turnaround days"
            value={String(composer.details.turnaroundDays)}
            onChange={(e) => {
              const parsed = Number(e.target.value);
              composer.setDetails({
                ...composer.details,
                turnaroundDays:
                  Number.isFinite(parsed) && parsed > 0
                    ? Math.floor(parsed)
                    : composer.details.turnaroundDays,
              });
            }}
          />
        </FormRow>

        <footer className="flex justify-end">
          <Button
            kind="gradient-primary"
            type="submit"
            disabled={!composer.canPublish}
            loading={composer.publishing}
            data-testid="composer-publish"
          >
            {composer.uploading ? "Uploading…" : "Publish"}
          </Button>
        </footer>
      </form>
    </div>
  );
}
