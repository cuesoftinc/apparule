import 'dart:async' show unawaited;

import 'package:apparule/src/core/async/run_action.dart';
import 'package:apparule/src/core/data/persistence_service.dart';
import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/app_haptics.dart';
import 'package:apparule/src/core/ui/edge_resist_physics.dart';
import 'package:apparule/src/core/ui/empty_state.dart';
import 'package:apparule/src/core/ui/gradient_refresh_spinner.dart';
import 'package:apparule/src/core/ui/skeleton.dart';
import 'package:apparule/src/core/ui/user_row.dart';
import 'package:apparule/src/core/utils/formats.dart';
import 'package:apparule/src/core/utils/seed_media.dart';
import 'package:apparule/src/features/feed/domain/designer_summary.dart';
import 'package:apparule/src/features/feed/domain/explore_results.dart';
import 'package:apparule/src/features/feed/domain/post.dart';
import 'package:apparule/src/features/feed/presentation/explore_view_model.dart';
import 'package:apparule/src/features/profile/presentation/follow_list_view_model.dart';
import 'package:apparule/src/features/profile/presentation/unfollow_confirm_sheet.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The C3 tag chips — real style tags from the seeded narrative (the
/// canvas chips are placeholders; honest data wins, same rule as the
/// story rail).
const List<String> _tagChips = <String>[
  'ankara',
  'bridal',
  'traditional',
  'menswear',
];

/// Recent-searches cap — web `RECENT_MAX` parity.
const int _recentMax = 5;

/// C3 — explore/discover (pages.md: search + 3-col grid; search-results
/// state = B2's sectioned Designers-above-Outfits; "Near me" re-ranks,
/// never hard-filters). The search field grows the recent-searches
/// dropdown on focus (D36) and the grid pull-refreshes (MI-5, D25).
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _search = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _query = '';
  String? _tag;
  bool _nearMe = true;
  List<String> _recent = <String>[];

  @override
  void initState() {
    super.initState();
    // Focus + text drive the dropdown and the in-field clear affordance.
    _searchFocus.addListener(_onSearchChrome);
    _search.addListener(_onSearchChrome);
    unawaited(_loadRecent());
  }

  void _onSearchChrome() => setState(() {});

  Future<void> _loadRecent() async {
    // Best-effort local view preference (web localStorage parity) — a
    // storage failure just means an empty dropdown.
    try {
      final recent = await ref
          .read(persistenceServiceProvider)
          .readRecentSearches();
      if (mounted) setState(() => _recent = recent);
    } on Object {
      // Storage unavailable — the dropdown simply won't persist.
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _submit(String value) {
    final query = value.trim();
    setState(() => _query = query);
    if (query.isEmpty) return;
    // Newest first, deduped, capped at 5 (web `submit` parity).
    final next = <String>[
      query,
      ..._recent.where((term) => term != query),
    ].take(_recentMax).toList();
    setState(() => _recent = next);
    unawaited(_persistRecent(next));
  }

  Future<void> _persistRecent(List<String> terms) async {
    try {
      await ref.read(persistenceServiceProvider).writeRecentSearches(terms);
    } on Object {
      // Storage unavailable — the dropdown simply won't persist.
    }
  }

  void _submitRecent(String term) {
    _search.text = term;
    _searchFocus.unfocus();
    _submit(term);
  }

  void _clear() {
    _search.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;
    final state = ref.watch(
      exploreViewModelProvider(query: _query, tag: _tag, nearMe: _nearMe),
    );
    // Recent-searches dropdown on focus with an empty field (web
    // ExploreView `showRecent` parity).
    final showRecent =
        _searchFocus.hasFocus && _recent.isNotEmpty && _search.text.isEmpty;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _search,
                focusNode: _searchFocus,
                onSubmitted: _submit,
                textInputAction: TextInputAction.search,
                style: typography.body14.copyWith(color: colors.text),
                decoration: InputDecoration(
                  hintText: l10n.exploreSearchHint,
                  hintStyle: typography.body14.copyWith(color: colors.text2),
                  prefixIcon: Icon(
                    LucideIcons.search,
                    size: 20,
                    color: colors.text2,
                  ),
                  // In-field clear (D36) — the empty-state CTA is no
                  // longer the only escape from a submitted query.
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : Semantics(
                          label: l10n.exploreClearSearch,
                          button: true,
                          child: InkResponse(
                            onTap: _clear,
                            radius: 18,
                            child: Icon(
                              LucideIcons.x,
                              size: 18,
                              color: colors.text2,
                            ),
                          ),
                        ),
                  isDense: true,
                  filled: true,
                  fillColor: colors.bgElev,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(radii.card),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(radii.card),
                    borderSide: BorderSide(color: colors.border),
                  ),
                ),
              ),
            ),
            if (showRecent)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Semantics(
                  container: true,
                  label: l10n.exploreRecentSearches,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.bgElev,
                      border: Border.all(color: colors.border),
                      borderRadius: BorderRadius.circular(radii.card),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        for (final term in _recent)
                          Semantics(
                            button: true,
                            child: InkWell(
                              onTap: () => _submitRecent(term),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Text(
                                  term,
                                  style: typography.body14.copyWith(
                                    color: colors.text,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                children: <Widget>[
                  _FilterChip(
                    label: l10n.exploreNearMe,
                    active: _nearMe,
                    onTap: () => setState(() => _nearMe = !_nearMe),
                  ),
                  for (final tag in _tagChips)
                    _FilterChip(
                      label: humanizeMeasureName(tag),
                      active: _tag == tag,
                      onTap: () => setState(
                        () => _tag = _tag == tag ? null : tag,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              // Value-preserving switch (CLASS 2): the MI-5 refresh and
              // the follow fan-out re-derive this family — the rendered
              // grid must survive the rebuild.
              child: switch (state) {
                AsyncValue(:final value?) => GradientRefreshSpinner(
                  // MI-5 pull-to-refresh (D25) — re-derives the family.
                  onRefresh: () => runAction(context, () {
                    ref.invalidate(exploreViewModelProvider);
                    return ref.read(
                      exploreViewModelProvider(
                        query: _query,
                        tag: _tag,
                        nearMe: _nearMe,
                      ).future,
                    );
                  }),
                  child: _ExploreResultsView(
                    results: value,
                    query: _query,
                    onClearSearch: _clear,
                  ),
                ),
                AsyncError(:final error) => Center(child: Text('$error')),
                _ => const _ExploreSkeleton(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        button: true,
        selected: active,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? colors.text : colors.bgElev,
              border: Border.all(
                color: active ? colors.text : colors.border,
              ),
              borderRadius: BorderRadius.circular(radii.pill),
            ),
            child: Text(
              label,
              style: typography.caption13.copyWith(
                fontWeight: FontWeight.w600,
                color: active ? colors.bg : colors.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The C3-explore-loading frame: a 3-col media-skeleton grid.
class _ExploreSkeleton extends StatelessWidget {
  const _ExploreSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: 12,
      itemBuilder: (context, index) => const Skeleton(kind: SkeletonKind.media),
    );
  }
}

class _ExploreResultsView extends ConsumerWidget {
  const _ExploreResultsView({
    required this.results,
    required this.query,
    required this.onClearSearch,
  });

  final ExploreResults results;
  final String query;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;
    final searching = query.isNotEmpty;

    if (results.posts.isEmpty && results.designers.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: EmptyState(
            kind: EmptyStateKind.explore,
            line: searching
                ? l10n.exploreNoResults(query)
                : l10n.exploreNoFilterResults,
            onCta: onClearSearch,
          ),
        ),
      );
    }

    // Top-edge overscroll drives the MI-5 spinner on both platforms.
    const physics = EdgeResistPhysics(parent: AlwaysScrollableScrollPhysics());
    final grid = SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      delegate: SliverChildBuilderDelegate(
        childCount: results.posts.length,
        (context, index) => _GridTile(post: results.posts[index]),
      ),
    );

    if (!searching) {
      return CustomScrollView(physics: physics, slivers: <Widget>[grid]);
    }

    // Search-results state (pages.md B2 [Directive 2026-07-18]):
    // Designers (UserRow + MI-7 Follow) above the Outfits grid, with
    // per-section empty copy.
    final sectionHeader = typography.body16SemiBold.copyWith(
      color: colors.text,
    );
    return CustomScrollView(
      physics: physics,
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          sliver: SliverToBoxAdapter(
            child: Text(l10n.exploreDesignersSection, style: sectionHeader),
          ),
        ),
        if (results.designers.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                l10n.exploreNoDesigners(query),
                style: typography.caption13.copyWith(color: colors.text2),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              childCount: results.designers.length,
              (context, index) =>
                  _DesignerRow(designer: results.designers[index]),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          sliver: SliverToBoxAdapter(
            child: Text(
              l10n.exploreOutfitsSection(results.posts.length),
              style: sectionHeader,
            ),
          ),
        ),
        grid,
      ],
    );
  }
}

class _DesignerRow extends ConsumerWidget {
  const _DesignerRow({required this.designer});

  final DesignerSummary designer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The canonical B2-parity search row is UserRow (design.md §8.2b):
    // the row body opens the C9 profile, the trailing button carries the
    // MI-7 morph — optimistic through FollowGraphController's overlay
    // (D02/D19: this frame, not after the round-trip), unfollow armed
    // behind the confirm sheet.
    final follows =
        ref.watch(followGraphControllerProvider)[designer.username] ??
        designer.viewerFollows;
    return UserRow(
      username: designer.username,
      meta: '${designer.displayName} · ${designer.locality}',
      image: seedMediaImageOrNull(designer.avatarUrl),
      verified: designer.verified,
      trailing: follows ? UserRowTrailing.following : UserRowTrailing.follow,
      onTap: () => PublicProfileRoute(
        username: designer.username,
      ).push<void>(context),
      onFollow: () => unawaited(
        runAction(
          context,
          () => ref
              .read(followGraphControllerProvider.notifier)
              .setFollow(designer.username, follow: true),
        ),
      ),
      onFollowingTap: () async {
        final confirmed = await showUnfollowConfirmSheet(
          context,
          username: designer.username,
          image: seedMediaImageOrNull(designer.avatarUrl),
        );
        if (confirmed && context.mounted) {
          await runAction(
            context,
            () => ref
                .read(followGraphControllerProvider.notifier)
                .setFollow(designer.username, follow: false),
          );
        }
      },
    );
  }
}

class _GridTile extends StatefulWidget {
  const _GridTile({required this.post});

  final Post post;

  @override
  State<_GridTile> createState() => _GridTileState();
}

class _GridTileState extends State<_GridTile> {
  /// Long-press peek (pages.md C3: "scale 0.97 + dim, MI haptic light").
  bool _peeking = false;

  void _setPeek(bool peeking) {
    if (_peeking == peeking) return;
    setState(() => _peeking = peeking);
    if (peeking) AppHaptics.light();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final post = widget.post;
    return Semantics(
      button: true,
      label: post.media.first.altText,
      child: GestureDetector(
        onTap: () => PostDetailRoute(id: post.id).push<void>(context),
        onLongPressStart: (_) => _setPeek(true),
        onLongPressEnd: (_) => _setPeek(false),
        onLongPressCancel: () => _setPeek(false),
        child: AnimatedScale(
          scale: _peeking ? 0.97 : 1,
          duration: const Duration(milliseconds: 120),
          child: ColoredBox(
            color: colors.border.withValues(alpha: 0.3),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Image(
                  image: seedMediaImage(post.media.first.url),
                  fit: BoxFit.cover,
                ),
                AnimatedOpacity(
                  opacity: _peeking ? 1 : 0,
                  duration: const Duration(milliseconds: 120),
                  child: const ColoredBox(color: Color(0x40000000)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
