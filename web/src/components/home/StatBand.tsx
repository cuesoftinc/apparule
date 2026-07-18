// A3 Problem strip — heading + 3 StatCards (canvas 186:38/186:39).
// Accuracy standard: product claims only (±2 cm target · 2 photos ·
// 30-day photo auto-delete), never invented research statistics.
import { StatCard } from "@/components/ui/StatCard";

const STATS = [
  { stat: "±2 cm", label: "target accuracy vs a professional tape measure" },
  { stat: "2 photos", label: "all it takes to build a full measurement profile" },
  { stat: "30 days", label: "capture photos auto-delete — measurements stay yours" },
] as const;

export function StatBand() {
  return (
    <section
      id="product"
      aria-labelledby="stats-heading"
      className="mx-auto w-full max-w-[1080px] scroll-mt-20 px-6 py-12"
    >
      <h2 id="stats-heading" className="text-title-lg font-bold text-text">
        Made-to-measure, without the guesswork
      </h2>
      <div className="mt-6 grid gap-6 sm:grid-cols-3">
        {STATS.map((s) => (
          <StatCard key={s.stat} stat={s.stat} label={s.label} />
        ))}
      </div>
    </section>
  );
}
