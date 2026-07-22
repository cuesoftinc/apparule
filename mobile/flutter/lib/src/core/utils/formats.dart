// Formatting utilities — the Dart port of web's `src/lib/format.ts` money/
// measurement formatters so the two clients render the identical strings
// over the same seed narrative (mobile-implementation.md §6). Money and
// measurement TEXT always pairs these with
// `FontFeature.tabularFigures()` (design.md §2 Type; c-series inventory
// tnum note).

/// The measurement unit toggle (MI-13) — `cm` is canonical storage;
/// `inch` is a display conversion only.
enum MeasureUnit {
  /// Centimetres (canonical).
  cm,

  /// Inches (display-side conversion, 2.54 cm/in).
  inch,
}

/// Centimetres per inch — the MI-13 display conversion factor.
const double cmPerInch = 2.54;

/// Kobo/cents → `₦45,000` (whole naira; v1 amounts are whole-naira).
String formatNaira(int cents, {String currency = 'NGN'}) {
  final naira = cents / 100;
  final wholeNaira = naira == naira.truncateToDouble();
  final magnitude = naira.abs();
  final formatted = wholeNaira
      ? _groupThousands(magnitude.truncate().toString())
      : _groupThousands(magnitude.toStringAsFixed(2));
  final symbol = currency == 'NGN' ? '₦' : '$currency ';
  return '${cents < 0 ? '−' : ''}$symbol$formatted';
}

String _groupThousands(String digits) {
  final parts = digits.split('.');
  final whole = parts.first;
  final grouped = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) grouped.write(',');
    grouped.write(whole[i]);
  }
  return parts.length > 1 ? '$grouped.${parts[1]}' : grouped.toString();
}

/// 42.5 → `42.5 cm` (or inches when the vault unit toggle flips, MI-13).
/// Always one decimal — the Figma idiom ("58.0 cm") keeps tabular columns
/// aligned ("92 cm" next to "78.5 cm" broke the tnum grid, audit
/// 2026-07-20).
String formatCm(double valueCm, [MeasureUnit unit = MeasureUnit.cm]) {
  if (unit == MeasureUnit.inch) {
    return '${(valueCm / cmPerInch).toStringAsFixed(1)} in';
  }
  return '${valueCm.toStringAsFixed(1)} cm';
}

/// Compact social counts ("12.4k", IG-style — web `formatCount` parity).
String formatCount(int value) {
  if (value < 1000) return '$value';
  if (value < 1000000) {
    final k = value / 1000;
    final rounded = k >= 100 ? k.roundToDouble() : (k * 10).round() / 10;
    return '${_trimTrailingZero(rounded)}k';
  }
  final m = (value / 1000000 * 10).round() / 10;
  return '${_trimTrailingZero(m)}m';
}

String _trimTrailingZero(double value) {
  return value == value.truncateToDouble()
      ? value.truncate().toString()
      : value.toString();
}

/// `snake_case` measurement names → "Snake Case" display labels (web
/// `humanizeMeasureName` parity).
String humanizeMeasureName(String name) {
  return name
      .split('_')
      .where((word) => word.isNotEmpty)
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');
}

// ---------------------------------------------------------------------------
// Timestamp text — the Dart port of web format.ts' relative/absolute
// labels, reading the DateTime's own fields (the seed derives instants
// from one injected clock, so phone and dashboard render the same story).
// ---------------------------------------------------------------------------

const List<String> _months = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Relative label for meta lines — the social "2h" idiom (web `formatAgo`
/// parity): `now` → `3h` → `3d` → `2w`, then the absolute `22 May`.
String formatAgo(DateTime at, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final elapsed = reference.difference(at);
  final days = elapsed.inDays;
  if (days <= 0) {
    final hours = elapsed.inHours;
    if (hours <= 0) {
      final minutes = elapsed.inMinutes;
      return minutes <= 0 ? 'now' : '${minutes}m';
    }
    return '${hours}h';
  }
  if (days < 7) return '${days}d';
  if (days < 30) return '${days ~/ 7}w';
  return formatDayMonth(at);
}

/// `22 May` (web `formatDateUtc` parity — the ≥30d fallback).
String formatDayMonth(DateTime at) => '${at.day} ${_months[at.month - 1]}';

/// `13:58` — wall-clock stamp (per-bubble thread times, web
/// `formatTimeUtc` parity).
String formatClock(DateTime at) {
  String pad(int n) => n.toString().padLeft(2, '0');
  return '${pad(at.hour)}:${pad(at.minute)}';
}

/// `Jul 10, 09:14` — timeline / older thread stamps (web
/// `formatDateTimeUtc` parity).
String formatDateClock(DateTime at) =>
    '${_months[at.month - 1]} ${at.day}, ${formatClock(at)}';

/// `Jul 12, 2026` — the C5 snapshot-picker date idiom.
String formatMonthDayYear(DateTime at) =>
    '${_months[at.month - 1]} ${at.day}, ${at.year}';

/// `Jul 16` — the C14 ledger meta idiom (canvas 267:8613 dates).
String formatMonthDay(DateTime at) => '${_months[at.month - 1]} ${at.day}';
