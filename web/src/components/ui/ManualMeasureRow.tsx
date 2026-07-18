"use client";

// ManualMeasureRow — design.md §8.2 (capture kit row, web-relevant for
// vault manual entry): tape-measure slider + numeric field + cm/in toggle ·
// state default / active / error (MI-13). Value changes animate the
// caller's sparkline preview via onChange.
import clsx from "clsx";
import { Input, type MeasureUnit } from "./Input";

export interface ManualMeasureRowProps {
  /** Measurement name, e.g. "shoulder_width" — label renders humanized. */
  name: string;
  valueCm: number | null;
  onChange: (valueCm: number | null) => void;
  unit: MeasureUnit;
  onUnitChange: (unit: MeasureUnit) => void;
  /** Sanity range (flows/vault.md §2) for the slider + validation. */
  min?: number;
  max?: number;
  error?: string;
  active?: boolean;
  className?: string;
}

export function humanizeMeasureName(name: string): string {
  return name
    .split("_")
    .map((w) => w[0]?.toUpperCase() + w.slice(1))
    .join(" ");
}

const CM_PER_IN = 2.54;

export function ManualMeasureRow({
  name,
  valueCm,
  onChange,
  unit,
  onUnitChange,
  min = 10,
  max = 200,
  error,
  active = false,
  className,
}: ManualMeasureRowProps) {
  const display =
    valueCm === null
      ? ""
      : unit === "cm"
        ? String(Math.round(valueCm * 10) / 10)
        : String(Math.round((valueCm / CM_PER_IN) * 10) / 10);

  const parse = (raw: string): number | null => {
    if (raw.trim() === "") return null;
    const num = Number(raw);
    if (!Number.isFinite(num)) return valueCm;
    return unit === "cm" ? num : num * CM_PER_IN;
  };

  return (
    <div
      data-state={error ? "error" : active ? "active" : "default"}
      className={clsx(
        "flex flex-col gap-2 rounded-card border p-4 transition-colors duration-120 ease-standard",
        error ? "border-error" : active ? "border-accent-start" : "border-border",
        "motion-reduce:transition-none",
        className,
      )}
    >
      <div className="flex items-center justify-between gap-3">
        <span className="text-body font-semibold text-text">
          {humanizeMeasureName(name)}
        </span>
        <Input
          kind="numeric"
          aria-label={`${humanizeMeasureName(name)} value`}
          value={display}
          onChange={(e) => onChange(parse(e.target.value))}
          unit={unit}
          onUnitChange={onUnitChange}
          className="w-36"
          error={undefined}
        />
      </div>
      {/* tape-measure themed slider: gradient fill + tick marks */}
      <div className="relative">
        <div
          aria-hidden
          className="pointer-events-none absolute inset-x-0 top-1/2 flex h-2 -translate-y-1/2 justify-between px-0.5"
        >
          {Array.from({ length: 21 }).map((_, i) => (
            <span
              key={i}
              className={clsx(
                "w-px bg-border",
                i % 5 === 0 ? "h-2" : "h-1 self-center",
              )}
            />
          ))}
        </div>
        <input
          type="range"
          aria-label={`${humanizeMeasureName(name)} slider`}
          min={min}
          max={max}
          step={0.5}
          value={valueCm ?? min}
          onChange={(e) => onChange(Number(e.target.value))}
          className="tape-slider relative w-full"
        />
      </div>
      {error ? <p className="text-micro text-error">{error}</p> : null}
    </div>
  );
}
