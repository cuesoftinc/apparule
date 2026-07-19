"use client";

// MI-7: unfollow always goes through a confirm sheet (prevents accidental).
import { Avatar } from "@/components/ui/Avatar";
import { Button } from "@/components/ui/Button";
import { Sheet } from "@/components/ui/Sheet";

export interface UnfollowTarget {
  username: string;
  unfollow: () => Promise<void>;
}

export function UnfollowConfirmSheet({
  target,
  onOpenChange,
}: {
  target: UnfollowTarget | null;
  onOpenChange: (open: boolean) => void;
}) {
  if (!target) return null;
  return (
    <Sheet open onOpenChange={onOpenChange} title="Unfollow?">
      <div className="flex flex-col items-center gap-4 py-2 text-center">
        <Avatar size={56} name={target.username} />
        <p className="text-body text-text-2">
          Their new outfits will stop showing in your feed.
        </p>
        <div className="flex w-full flex-col gap-2">
          <Button
            kind="destructive"
            onClick={() => {
              void target.unfollow();
              onOpenChange(false);
            }}
          >
            Unfollow @{target.username}
          </Button>
          <Button kind="quiet" onClick={() => onOpenChange(false)}>
            Cancel
          </Button>
        </div>
      </div>
    </Sheet>
  );
}
