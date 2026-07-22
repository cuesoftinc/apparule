/// One money parser for every amount field (the interaction audit's
/// CLASS 8 lock — hand-rolled per-surface parsing let the quote sheet's
/// own "45,000" hint disable its CTA, D05).
///
/// Strips everything but digits and dots ("₦45,000" → 45000, "45 000.50"
/// → 45000.5), then parses. Null for empty or unparseable input — the
/// callers' CTA gate.
double? parseAmount(String input) {
  final cleaned = input.replaceAll(RegExp(r'[^\d.]'), '');
  if (cleaned.isEmpty) return null;
  return double.tryParse(cleaned);
}

/// [parseAmount] in minor units (kobo/cents) — what the repositories
/// speak. Null propagates; fractions round to the nearest minor unit.
int? parseAmountMinor(String input) {
  final amount = parseAmount(input);
  return amount == null ? null : (amount * 100).round();
}
