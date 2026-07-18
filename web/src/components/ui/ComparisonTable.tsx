// ComparisonTable — design.md §8.2b Home section kit: Cloud vs OSS + CTA
// row (pages.md A9: Cloud column ends in Try Cloud, OSS column in Self
// Host → docs quickstart). Figma master 143:2 (enriched landing, 2026-07-18):
// icon/check (success) = included, icon/x (text-2) = not available; 100px
// rows, 140px CTA columns closing in "Start on Cloud" / "Self-host it".
import clsx from "clsx";
import { Check, X } from "lucide-react";
import { Button } from "./Button";

export interface ComparisonRow {
  feature: string;
  cloud: boolean | string;
  oss: boolean | string;
}

// The Figma master's row set (143:9–143:59) — capability rows only, no
// invented pricing (accuracy standard).
const DEFAULT_ROWS: ComparisonRow[] = [
  { feature: "Instant setup", cloud: true, oss: false },
  { feature: "Automatic updates", cloud: true, oss: false },
  { feature: "Custom domain", cloud: true, oss: true },
  { feature: "Runs on your infrastructure", cloud: false, oss: true },
  { feature: "Offline / air-gapped", cloud: false, oss: true },
  { feature: "Priority support & SLA", cloud: true, oss: false },
];

function Cell({ value }: { value: boolean | string }) {
  if (value === true) return <Check size={24} className="mx-auto text-success" aria-label="Included" />;
  if (value === false) return <X size={24} className="mx-auto text-text-2" aria-label="Not included" />;
  return <span className="text-caption text-text-2">{value}</span>;
}

export interface ComparisonTableProps {
  rows?: ComparisonRow[];
  onTryCloud?: () => void;
  onSelfHost?: () => void;
  className?: string;
}

export function ComparisonTable({
  rows = DEFAULT_ROWS,
  onTryCloud,
  onSelfHost,
  className,
}: ComparisonTableProps) {
  return (
    <div
      className={clsx(
        "w-full max-w-[640px] overflow-hidden rounded-card border border-border bg-bg-elev",
        className,
      )}
    >
      <table className="w-full border-collapse text-body">
        <thead>
          <tr className="border-b border-border text-left">
            {/* Figma master: Feature reads Caption/13 Semi Bold in text-2 */}
            <th className="h-25 px-6 text-caption font-semibold text-text-2">
              Feature
            </th>
            <th className="h-25 w-35 text-center text-body-lg font-semibold text-text">
              Cloud
            </th>
            <th className="h-25 w-35 px-6 pl-0 text-center text-body-lg font-semibold text-text">
              Self-host
            </th>
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr key={row.feature} className="border-b border-border">
              <td className="h-25 px-6 text-text">{row.feature}</td>
              <td className="h-25 text-center">
                <Cell value={row.cloud} />
              </td>
              <td className="h-25 px-6 pl-0 text-center">
                <Cell value={row.oss} />
              </td>
            </tr>
          ))}
          <tr data-testid="cta-row">
            <td className="h-25 px-6" />
            <td className="h-25 text-center">
              <Button kind="gradient-primary" size="sm" onClick={onTryCloud}>
                Start on Cloud
              </Button>
            </td>
            <td className="h-25 px-6 pl-0 text-center">
              <Button kind="quiet" size="sm" onClick={onSelfHost}>
                Self-host it
              </Button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  );
}
