// ComparisonTable — design.md §8.2b Home section kit: Cloud vs OSS + CTA
// row (pages.md A9: Cloud column ends in Try Cloud, OSS column in Self
// Host → docs quickstart).
import clsx from "clsx";
import { Check, Minus } from "lucide-react";
import { Button } from "./Button";

export interface ComparisonRow {
  feature: string;
  cloud: boolean | string;
  oss: boolean | string;
}

const DEFAULT_ROWS: ComparisonRow[] = [
  { feature: "AI body measurement", cloud: true, oss: true },
  { feature: "Social feed & commissions", cloud: true, oss: true },
  { feature: "Escrow payments (Paystack)", cloud: true, oss: "bring your own keys" },
  { feature: "Managed hosting & backups", cloud: true, oss: false },
  { feature: "Your data on your metal", cloud: false, oss: true },
  { feature: "Support", cloud: "included", oss: "community" },
];

function Cell({ value }: { value: boolean | string }) {
  if (value === true) return <Check size={18} className="mx-auto text-success" aria-label="Included" />;
  if (value === false) return <Minus size={18} className="mx-auto text-text-2" aria-label="Not included" />;
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
    // Figma master (Stage 5): the table sits in a bordered card; the
    // Feature header reads as a caption, CTAs are "Start on Cloud" /
    // "Self-host it".
    <div
      className={clsx(
        "w-full max-w-2xl overflow-hidden rounded-card border border-border bg-bg-elev",
        className,
      )}
    >
      <table className="w-full border-collapse text-body">
        <thead>
          <tr className="border-b border-border text-left">
            <th className="px-4 py-3 text-caption font-normal text-text-2">
              Feature
            </th>
            <th className="w-36 py-3 text-center font-semibold text-text">Cloud</th>
            <th className="w-36 px-4 py-3 text-center font-semibold text-text">
              Self-host
            </th>
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr key={row.feature} className="border-b border-border">
              <td className="px-4 py-3 text-text">{row.feature}</td>
              <td className="py-3 text-center">
                <Cell value={row.cloud} />
              </td>
              <td className="px-4 py-3 text-center">
                <Cell value={row.oss} />
              </td>
            </tr>
          ))}
          <tr data-testid="cta-row">
            <td className="py-4" />
            <td className="py-4 text-center">
              <Button kind="gradient-primary" size="sm" onClick={onTryCloud}>
                Start on Cloud
              </Button>
            </td>
            <td className="px-4 py-4 text-center">
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
