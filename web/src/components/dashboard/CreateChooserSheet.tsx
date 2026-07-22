"use client";

// Create chooser (M-11, Figma 548:9490): the rail's Create action opens a
// two-option chooser on both platforms — "Take measurements" (→ B4 capture
// options) and "Post an outfit" (→ B5; designer-gated — non-designers land
// on the become-a-designer upsell there). C1b choice-card language: icon +
// title + subtitle + chevron; the measurements card is primary (accent
// border, 1.5px per the master).
import clsx from "clsx";
import Link from "next/link";
import { Camera, ChevronRight, Shirt, type LucideIcon } from "lucide-react";
import { useAuth } from "@/auth/AuthContext";
import { Sheet } from "@/components/ui/Sheet";

function ChoiceCard({
  href,
  icon: Icon,
  title,
  subtitle,
  primary = false,
  onNavigate,
}: {
  href: string;
  icon: LucideIcon;
  title: string;
  subtitle: string;
  primary?: boolean;
  onNavigate: () => void;
}) {
  return (
    <Link
      href={href}
      onClick={onNavigate}
      data-testid={`create-choice-${primary ? "measure" : "post"}`}
      className={clsx(
        "flex items-center gap-4 rounded-card bg-bg-elev p-4 text-left",
        "transition-transform duration-120 ease-standard active:scale-[0.99]",
        "motion-reduce:transition-none motion-reduce:active:scale-100",
        primary
          ? "border-[1.5px] border-accent-start"
          : "border border-border hover:border-text-2/40",
      )}
    >
      <span className="grid size-10 shrink-0 place-items-center rounded-pill bg-accent-start/12 text-accent-start">
        <Icon size={20} aria-hidden="true" />
      </span>
      <span className="flex min-w-0 flex-1 flex-col gap-0.5">
        <span className="text-body font-semibold text-text">{title}</span>
        <span className="text-caption text-text-2">{subtitle}</span>
      </span>
      <ChevronRight size={16} className="shrink-0 text-text-2" aria-hidden />
    </Link>
  );
}

export function CreateChooserSheet({
  open,
  onOpenChange,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}) {
  const { account } = useAuth();
  const isDesigner = account?.designer.enabled ?? false;
  const close = () => onOpenChange(false);
  return (
    <Sheet open={open} onOpenChange={onOpenChange} title="Create">
      <div className="flex flex-col gap-3">
        <ChoiceCard
          href="/dashboard/vault?capture=1"
          icon={Camera}
          title="Take measurements"
          subtitle="Two photos — about a minute"
          primary
          onNavigate={close}
        />
        <ChoiceCard
          href="/dashboard/create"
          icon={Shirt}
          title="Post an outfit"
          subtitle={
            isDesigner
              ? "Share a look with its fit data"
              : "Become a designer to post"
          }
          onNavigate={close}
        />
      </div>
    </Sheet>
  );
}
