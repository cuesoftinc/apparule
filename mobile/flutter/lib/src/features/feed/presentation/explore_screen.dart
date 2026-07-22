import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/avatar.dart';
import 'package:apparule/src/core/ui/button.dart';
import 'package:apparule/src/core/ui/empty_state.dart';
import 'package:apparule/src/core/ui/skeleton.dart';
import 'package:apparule/src/core/utils/formats.dart';
import 'package:apparule/src/core/utils/seed_media.dart';
import 'package:apparule/src/features/feed/domain/designer_summary.dart';
import 'package:apparule/src/features/feed/domain/explore_results.dart';
import 'package:apparule/src/features/feed/domain/post.dart';
import 'package:apparule/src/features/feed/presentation/explore_view_model.dart';
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

/// C3 — explore/discover (pages.md: search + 3-col grid; search-results
/// state = B2's sectioned Designers-above-Outfits; "Near me" re-ranks,
/// never hard-filters).
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  String? _tag;
  bool _nearMe = true;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _submit(String value) => setState(() => _query = value.trim());

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

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _search,
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
              child: switch (state) {
                AsyncData(:final value) => _ExploreResultsView(
                  results: value,
                  query: _query,
                  onClearSearch: _clear,
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
      return CustomScrollView(slivers: <Widget>[grid]);
    }

    // Search-results state (pages.md B2 [Directive 2026-07-18]):
    // Designers (UserRow + MI-7 Follow) above the Outfits grid, with
    // per-section empty copy.
    final sectionHeader = typography.body16SemiBold.copyWith(
      color: colors.text,
    );
    return CustomScrollView(
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
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: <Widget>[
          Avatar(
            name: designer.username,
            image: seedMediaImageOrNull(designer.avatarUrl),
            badge: designer.verified
                ? AvatarBadge.designerVerified
                : AvatarBadge.none,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  designer.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.body14.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.text,
                  ),
                ),
                Text(
                  '${designer.displayName} · ${designer.locality}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.caption13.copyWith(color: colors.text2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Button(
            label: designer.viewerFollows
                ? l10n.exploreFollowing
                : l10n.exploreFollow,
            kind: designer.viewerFollows
                ? ButtonKind.quiet
                : ButtonKind.gradientPrimary,
            size: ButtonSize.sm,
            onPressed: () => ref
                .read(exploreFollowControllerProvider.notifier)
                .setFollow(
                  designer.username,
                  follow: !designer.viewerFollows,
                ),
          ),
        ],
      ),
    );
  }
}

class _GridTile extends StatelessWidget {
  const _GridTile({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Semantics(
      button: true,
      label: post.media.first.altText,
      child: GestureDetector(
        onTap: () => PostDetailRoute(id: post.id).push<void>(context),
        child: ColoredBox(
          color: colors.border.withValues(alpha: 0.3),
          child: Image(
            image: seedMediaImage(post.media.first.url),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
