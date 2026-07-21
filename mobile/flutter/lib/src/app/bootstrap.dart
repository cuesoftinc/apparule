import 'package:apparule/src/app/app.dart';
import 'package:apparule/src/app/di.dart';
import 'package:apparule/src/core/utils/app_flavor.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Riverpod 3 trimmed flutter_riverpod's export surface — Override lives in
// the annotation package's re-exports.
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

/// Shared bootstrap (mobile-implementation.md §3): binds the flavor and the
/// entrypoint's override set into one ProviderScope and runs the app.
///
/// Firebase is deliberately NOT initialized here yet — the deps ship this
/// wave, `flutterfire configure` + `Firebase.initializeApp` land with the
/// auth cutover (§2/§9). Error zones/crash reporting join at that point.
Future<void> bootstrap({
  required AppFlavor flavor,
  List<Override> overrides = const <Override>[],
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: <Override>[
        appFlavorProvider.overrideWith((ref) => flavor),
        ...overrides,
      ],
      child: const ApparuleApp(),
    ),
  );
}
