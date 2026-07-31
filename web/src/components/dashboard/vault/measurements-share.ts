// A-11 measurement share text (decisions.md, ratified 2026-07-31) — the
// WhatsApp-to-tailor flow: latest values as readable lines in the active
// display unit, plus the product link. Shared by the vault Share action
// and the post share sheet's opt-in.
import { formatCm } from "@/lib/format";
import type { Measurement } from "@/models";
import { humanizeMeasureName } from "@/components/ui/ManualMeasureRow";

export const APPARULE_LINK = "https://apparule.cuesoft.io";

/**
 * "My measurements (Apparule)" + one line per latest value + the link.
 * Values speak the display unit (inches by default, A-9); the order is
 * the vault's latest-per-metric order (template order after a scan).
 */
export function measurementsShareText(
  latest: Measurement[],
  unit: "cm" | "in" = "in",
): string {
  const lines = latest.map(
    (m) => `${humanizeMeasureName(m.name)}: ${formatCm(m.value_cm, unit)}`,
  );
  return ["My measurements (Apparule)", ...lines, APPARULE_LINK].join("\n");
}
