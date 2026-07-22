import 'package:apparule/src/app/app.dart';
import 'package:apparule/src/app/di.dart';
import 'package:apparule/src/core/utils/app_flavor.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Riverpod 3 trimmed flutter_riverpod's export surface — Override lives in
// the annotation package's re-exports.
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

/// Shared bootstrap (mobile-implementation.md §3): binds the flavor and the
/// entrypoint's override set into one ProviderScope and runs the app.
///
/// [firebaseOptions] is the §2/§9 Firebase seam: an entrypoint passes its
/// flavor's `DefaultFirebaseOptions.currentPlatform` (from the
/// `flutterfire configure`-generated options file — `firebase_options
/// .dart` for prod, `firebase_options_dev.dart` for dev) and pairs it
/// with `firebaseAuthRepositoryOverride()`. No entrypoint passes it yet —
/// generating the options files is blocked on `firebase login --reauth`
/// (see the auth-cutover PR). Error zones/crash reporting join when that
/// lands.
Future<void> bootstrap({
  required AppFlavor flavor,
  List<Override> overrides = const <Override>[],
  FirebaseOptions? firebaseOptions,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (firebaseOptions != null) {
    await Firebase.initializeApp(options: firebaseOptions);
  }
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
