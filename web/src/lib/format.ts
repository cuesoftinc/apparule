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
