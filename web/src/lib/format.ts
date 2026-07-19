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

/** 42.5 → "42.5 cm" (or inches when the vault unit toggle flips, MI-13). */
export function formatCm(valueCm: number, unit: "cm" | "in" = "cm"): string {
  if (unit === "in") {
    const inches = valueCm / 2.54;
    return `${inches.toFixed(1)} in`;
  }
  return `${valueCm % 1 === 0 ? valueCm.toFixed(0) : valueCm.toFixed(1)} cm`;
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
  return new Date(iso).toLocaleDateString("en-NG", {
    month: "short",
    day: "numeric",
  });
}
