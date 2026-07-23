import 'package:apparule/src/features/measurements/data/measurement_repository.dart';
import 'package:apparule/src/features/profile/data/profile_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'composer_view_model.g.dart';

/// What the C15 composer needs beyond its own local draft: the vault's
/// LATEST session id — the ref the snapshot-attach toggle (default ON)
/// stamps onto the published post — and the signed-in designer's display
/// name for the required alt-text default ("Outfit by {designer}",
/// design.md §5). An empty vault resolves a null ref: the toggle stays
/// interactive, the publish simply carries no snapshot.
typedef ComposerContext = ({
  String? latestSnapshotSessionId,
  String designerDisplayName,
});

/// C15's orchestration point — the one place the composer meets the
/// measurement and profile repositories (ViewModels orchestrate;
/// repositories never reference each other, mobile-implementation.md §3).
/// Post mutations themselves route through the `EngagementActions`
/// façade (CLASS 1), never from here.
@riverpod
Future<ComposerContext> composerContext(Ref ref) async {
  // vaultSessions is newest-first by contract — the head is the ref.
  final sessions = await ref
      .watch(measurementRepositoryProvider)
      .vaultSessions();
  final profile = await ref.watch(profileRepositoryProvider).me();
  return (
    latestSnapshotSessionId: sessions.isEmpty ? null : sessions.first.id,
    designerDisplayName: profile?.displayName ?? '',
  );
}
