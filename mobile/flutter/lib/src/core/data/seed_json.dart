import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Shared seed-JSON conventions for the `*Fake` repositories
/// (mobile-implementation.md §6).
///
/// Loads a seed asset, or `null` when the bundle has no such asset — §6
/// seeds are dev-flavor-scoped, so a prod bundle (fakes, no seeds — the
/// pre-API interim) degrades to empty domains instead of crashing.
Future<Map<String, dynamic>?> loadSeedJson(
  AssetBundle bundle,
  String asset,
) async {
  try {
    final raw = await bundle.loadString(asset);
    return jsonDecode(raw) as Map<String, dynamic>;
    // A missing asset surfaces as FlutterError (an Error subclass) — the
    // one Error the fakes legitimately absorb (same rule as the C6 wave's
    // MeasurementRepositoryFake).
    // ignore: avoid_catching_errors
  } on FlutterError {
    return null;
  }
}

/// `days_ago` → instant (web seed `daysAgo()` parity: computed at load so
/// recency narratives never age out of their states).
DateTime seedDaysAgo(DateTime now, num days) => now.subtract(
  Duration(milliseconds: (days * Duration.millisecondsPerDay).round()),
);

/// `days_ago` + optional `"HH:mm"` → instant (web seed `daysAgoAt()`
/// parity — the PR #102 cadence rule: whole-day offsets pin a plausible
/// local time so multi-event stories read as days of real back-and-forth,
/// never one same-minute batch; same-day offsets stay relative to boot).
DateTime seedDaysAgoAt(DateTime now, num days, String? time) {
  final base = seedDaysAgo(now, days);
  if (time == null) return base;
  final parts = time.split(':');
  return DateTime(
    base.year,
    base.month,
    base.day,
    int.parse(parts[0]),
    int.parse(parts[1]),
  );
}

/// `hours_ago` → instant (web seed `hoursAgo()` parity).
DateTime seedHoursAgo(DateTime now, num hours) => now.subtract(
  Duration(milliseconds: (hours * Duration.millisecondsPerHour).round()),
);
