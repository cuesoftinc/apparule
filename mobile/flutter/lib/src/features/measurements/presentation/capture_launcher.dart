import 'package:apparule/src/features/measurements/data/capture_guide_flag.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The one capture entry gesture (mobile-implementation.md §10): guide on
/// first run, straight to the viewfinder once the persisted flag is set.
/// Shared by the ➕ chooser's "Take measurements" card (M-11), the C1b
/// interstitial, and the vault's capture option cards.
Future<void> launchCaptureFlow(BuildContext context, WidgetRef ref) async {
  final guideSeen = await ref.read(captureGuideFlagProvider.future);
  if (!context.mounted) return;
  if (guideSeen) {
    await const CaptureRoute().push<void>(context);
  } else {
    await const CaptureGuideRoute().push<void>(context);
  }
}
