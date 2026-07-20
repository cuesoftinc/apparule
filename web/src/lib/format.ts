// Formatting utilities — money and measurements render with tabular
// numerals (design.md §2 Type); pair these with the `tnum` class.

/** Kobo/cents → "₦45,000" (whole naira; v1 amounts are whole-naira). */
export function formatNaira(cents: number, currency = "NGN"): string {
  const naira = cents / 100;
  const formatted = new Intl.NumberFormat("en-NG", {
    maximumFractionDigits: naira % 1 === 0 ? 0 : 2,
  }).format(Math.abs(naira));
  const symbol = currency === "NGN" ? "₦" : `${currency} `;
  return `${cents < 0 ? "−" : ""}${symbol}${formatted}`;
}

/**
 * 42.5 → "42.5 cm" (or inches when the vault unit toggle flips, MI-13).
 * Always one decimal — the Figma idiom ("58.0 cm") keeps tabular columns
 * aligned; "92 cm" next to "78.5 cm" broke the tnum grid (audit 2026-07-20).
 */
export function formatCm(valueCm: number, unit: "cm" | "in" = "cm"): string {
  if (unit === "in") {
    const inches = valueCm / 2.54;
    return `${inches.toFixed(1)} in`;
  }
  return `${valueCm.toFixed(1)} cm`;
}

/** Compact social counts ("12.4k followers", IG-style — Figma 182:969). */
export function formatCount(value: number): string {
  if (value < 1000) return String(value);
  if (value < 1_000_000) {
    const k = value / 1000;
    return `${k >= 100 ? Math.round(k) : Math.round(k * 10) / 10}k`;
  }
  const m = value / 1_000_000;
  return `${Math.round(m * 10) / 10}m`;
}

/**
 * Full relative phrase for prose meta lines ("2d ago", "just now",
 * "on 22 May"). formatAgo alone switches to an absolute date after 30d, so
 * templates that append " ago" produced "Updated 22 May ago" (system QA).
 */
export function formatAgoPhrase(iso: string, now: Date = new Date()): string {
  const days = Math.floor(
    (now.getTime() - new Date(iso).getTime()) / (24 * 60 * 60 * 1000),
  );
  if (days >= 30) return `on ${formatAgo(iso, now)}`;
  const label = formatAgo(iso, now);
  return label === "now" ? "just now" : `${label} ago`;
}

/** Relative day label for meta lines ("today", "3d", "2w"). */
export function formatAgo(iso: string, now: Date = new Date()): string {
  const ms = now.getTime() - new Date(iso).getTime();
  const days = Math.floor(ms / (24 * 60 * 60 * 1000));
  if (days <= 0) {
    const hours = Math.floor(ms / (60 * 60 * 1000));
    return hours <= 0 ? "now" : `${hours}h`;
  }
  if (days < 7) return `${days}d`;
  if (days < 30) return `${Math.floor(days / 7)}w`;
  return formatDateUtc(iso);
}

// ---------------------------------------------------------------------------
// UTC-derived timestamp text. These are pure functions of the instant, so
// the server and every client render the identical string regardless of
// host timezone — hydrated <time> labels never mismatch or flip (the local
// alternative emits different calendar days/times across timezones for the
// same instant). The API speaks UTC ISO strings; these read that same
// UTC clock.
// ---------------------------------------------------------------------------

const UTC_MONTHS = [
  "Jan",
  "Feb",
  "Mar",
  "Apr",
  "May",
  "Jun",
  "Jul",
  "Aug",
  "Sep",
  "Oct",
  "Nov",
  "Dec",
];

/** "13:58" — UTC wall-clock time (per-bubble thread stamps). */
export function formatTimeUtc(iso: string): string {
  const d = new Date(iso);
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${pad(d.getUTCHours())}:${pad(d.getUTCMinutes())}`;
}

/** "22 May" — UTC calendar date (the ≥30d relative-label fallback). */
export function formatDateUtc(iso: string): string {
  const d = new Date(iso);
  return `${d.getUTCDate()} ${UTC_MONTHS[d.getUTCMonth()]}`;
}

/** "Mar 4, 13:58" — UTC date + time (older-than-today thread bubbles). */
export function formatDateTimeUtc(iso: string): string {
  const d = new Date(iso);
  return `${UTC_MONTHS[d.getUTCMonth()]} ${d.getUTCDate()}, ${formatTimeUtc(iso)}`;
}

/** True when both instants fall on the same UTC calendar day. */
export function isSameUtcDay(a: string | Date, b: string | Date): boolean {
  return (
    new Date(a).toISOString().slice(0, 10) ===
    new Date(b).toISOString().slice(0, 10)
  );
}
