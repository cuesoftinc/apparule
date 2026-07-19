"use client";

// PostCard ⋯ overflow — copy link (MI-9 share target /p/{id}) + report
// (SOC-009 reason enum). Secondary flows live in sheets (design.md §3).
import { useState } from "react";
import type { Post, ReportReason } from "@/models";
import { useReport } from "@/controllers/use-moderation";
import { Button } from "@/components/ui/Button";
import { MenuItem } from "@/components/ui/Popover";
import { Select } from "@/components/ui/Select";
import { Sheet } from "@/components/ui/Sheet";
import { Input } from "@/components/ui/Input";
import { useToasts } from "../toast-context";

const REPORT_REASONS: { value: ReportReason; label: string }[] = [
  { value: "spam", label: "Spam" },
  { value: "inappropriate", label: "Inappropriate content" },
  { value: "counterfeit", label: "Counterfeit item" },
  { value: "harassment", label: "Harassment" },
  { value: "other", label: "Other" },
];

export interface PostOptionsSheetProps {
  post: Post | null;
  onOpenChange: (open: boolean) => void;
  /** MI-9: the view flashes the card's gradient border on copy. */
  onCopied?: (postId: string) => void;
}

export function PostOptionsSheet({
  post,
  onOpenChange,
  onCopied,
}: PostOptionsSheetProps) {
  const { showToast } = useToasts();
  const { submitting, fileReport } = useReport();
  const [reporting, setReporting] = useState(false);
  const [reason, setReason] = useState<ReportReason | undefined>();
  const [detail, setDetail] = useState("");

  const close = (open: boolean) => {
    onOpenChange(open);
    if (!open) {
      setReporting(false);
      setReason(undefined);
      setDetail("");
    }
  };

  if (!post) return null;

  const copyLink = async () => {
    const url = `${window.location.origin}/p/${post.id}`;
    try {
      await navigator.clipboard.writeText(url);
    } catch {
      // clipboard unavailable — still surface the link via toast
    }
    showToast({ kind: "neutral", message: "Link copied" });
    onCopied?.(post.id);
    close(false);
  };

  const submitReport = async () => {
    if (!reason) return;
    try {
      await fileReport("post", post.id, reason, detail || undefined);
      showToast({ kind: "success", message: "Report sent — thank you" });
      close(false);
    } catch {
      showToast({ kind: "error", message: "Couldn't send the report" });
    }
  };

  return (
    <Sheet
      open={post !== null}
      onOpenChange={close}
      title={reporting ? "Report post" : "Post options"}
    >
      {reporting ? (
        <form
          className="flex flex-col gap-4"
          onSubmit={(e) => {
            e.preventDefault();
            void submitReport();
          }}
        >
          <Select
            aria-label="Report reason"
            placeholder="Why are you reporting this?"
            options={REPORT_REASONS}
            value={reason}
            onValueChange={(v) => setReason(v as ReportReason)}
          />
          <Input
            kind="textarea"
            aria-label="Report details"
            placeholder="Anything the moderators should know (optional)"
            maxLength={500}
            value={detail}
            onChange={(e) => setDetail(e.target.value)}
          />
          <footer className="flex justify-end gap-2">
            <Button kind="quiet" onClick={() => setReporting(false)}>
              Back
            </Button>
            <Button
              kind="destructive"
              disabled={!reason}
              loading={submitting}
              type="submit"
            >
              Report
            </Button>
          </footer>
        </form>
      ) : (
        // role="menu": MenuItem renders role="menuitem", which ARIA
        // requires to be owned by a menu container (system QA a11y fix).
        <div role="menu" aria-label="Post options">
          <MenuItem label="Copy link" onSelect={() => void copyLink()} />
          <MenuItem
            label="Report post"
            destructive
            onSelect={() => setReporting(true)}
          />
        </div>
      )}
    </Sheet>
  );
}
