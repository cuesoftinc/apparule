import 'package:apparule/src/core/async/run_action.dart';
import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/app_bar.dart';
import 'package:apparule/src/core/ui/app_switch.dart';
import 'package:apparule/src/core/ui/button.dart';
import 'package:apparule/src/core/utils/seed_media.dart';
import 'package:apparule/src/features/feed/data/media_picker_service.dart';
import 'package:apparule/src/features/feed/domain/post.dart';
import 'package:apparule/src/features/feed/presentation/composer_view_model.dart';
import 'package:apparule/src/features/feed/presentation/engagement_actions.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// C15 — the designer post composer (M-11; canvas 551:2866 empty /
/// 551:4152 ready / 552:2 uploading): centered "New post" bar, the
/// media grid (device picker behind the `MediaPickerService` seam;
/// remove dots; dashed add affordances), the required caption, the
/// snapshot-attach toggle (default ON — the M-11 differentiator: posts
/// carry the fit data this look was tailored for), and the Post CTA
/// (disabled until ≥1 photo AND a caption; loading while the publish is
/// in flight, every input locked behind null handlers).
///
/// The ratified v1 contract mirrors web B5's media picker (≤10,
/// JPEG/PNG/WebP, ≤10 MB) + caption; style tags / base price /
/// turnaround stay web-B5-only. Publish routes through
/// `EngagementActions.createPost` (CLASS 1) inside `runAction`
/// (CLASS 4): a failed publish toasts and KEEPS the draft — media,
/// caption and toggle all survive for the retry.
class ComposerScreen extends ConsumerStatefulWidget {
  const ComposerScreen({
    this.initialMedia = const <PickedMedia>[],
    this.initialCaption = '',
    this.debugUploading = false,
    super.key,
  });

  /// Golden-scenario seams: the draft state is screen-local (no
  /// repository holds an unpublished draft), so the ready/uploading
  /// canvas cells pre-arrange it here. Runtime entries pass nothing.
  final List<PickedMedia> initialMedia;
  final String initialCaption;

  /// Renders the publish-in-flight chrome statically (per-tile
  /// "Uploading…" strips + loading CTA + locked inputs) — the state is
  /// otherwise transient behind the CTA tap.
  final bool debugUploading;

  /// The ratified media contract (pages.md B5, decided — mirrored to
  /// C15): ≤10 items, JPEG/PNG/WebP, ≤10 MB each.
  static const int maxPhotos = 10;
  static const int maxBytes = 10 * 1024 * 1024;
  static const Set<String> allowedTypes = <String>{
    'image/jpeg',
    'image/png',
    'image/webp',
  };

  @override
  ConsumerState<ComposerScreen> createState() => _ComposerScreenState();
}

class _ComposerScreenState extends ConsumerState<ComposerScreen> {
  final TextEditingController _caption = TextEditingController();
  final List<PickedMedia> _media = <PickedMedia>[];
  bool _attachSnapshot = true;
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _media.addAll(widget.initialMedia);
    _caption.text = widget.initialCaption;
    _posting = widget.debugUploading;
    // The Post gate re-evaluates per keystroke (caption required —
    // the D54 idiom; nothing writes the controller during build, so
    // no deferral is needed).
    _caption.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  /// Web `useComposer.addFiles` parity, over the picker seam: fill the
  /// remaining room, gate each candidate on type then size, and voice
  /// the FIRST violation — an overflowing selection overrides with the
  /// count copy (the web `dropError` ordering).
  Future<void> _addPhotos() async {
    final l10n = context.l10n;
    final room = ComposerScreen.maxPhotos - _media.length;
    final picked = await ref
        .read(mediaPickerServiceProvider)
        .pickImages(limit: room);
    if (!mounted || picked.isEmpty) return;

    String? rejection;
    final accepted = <PickedMedia>[];
    for (final item in picked.take(room)) {
      if (!ComposerScreen.allowedTypes.contains(item.mimeType)) {
        rejection ??= l10n.composerRejectedType;
        continue;
      }
      if (item.sizeBytes > ComposerScreen.maxBytes) {
        rejection ??= l10n.composerRejectedSize;
        continue;
      }
      accepted.add(item);
    }
    if (picked.length > room) rejection = l10n.composerRejectedCount;

    setState(() => _media.addAll(accepted));
    if (rejection != null) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(rejection)));
    }
  }

  Future<void> _post() async {
    final l10n = context.l10n;
    setState(() => _posting = true);
    // CLASS 4: a failed publish toasts and keeps the draft — the media
    // grid, caption and toggle stay exactly as the designer left them.
    final ok = await runAction(context, () async {
      final composerContext = await ref.read(composerContextProvider.future);
      final altText = l10n.composerAltTextDefault(
        composerContext.designerDisplayName,
      );
      await ref
          .read(engagementActionsProvider.notifier)
          .createPost(
            caption: _caption.text.trim(),
            media: <PostMedia>[
              // Alt text is required (design.md §5) and mobile v1 has no
              // alt-text field — every item carries the default.
              for (final item in _media)
                PostMedia(url: item.url, altText: altText),
            ],
            snapshotSessionId: _attachSnapshot
                ? composerContext.latestSnapshotSessionId
                : null,
          );
    });
    if (!mounted) return;
    setState(() => _posting = false);
    if (ok) {
      // The post leads the feed (web B5: publish → the feed) — land the
      // author on it.
      const HomeRoute().go(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;

    final canPost =
        _media.isNotEmpty && _caption.text.trim().isNotEmpty && !_posting;

    OutlineInputBorder inputBorder() => OutlineInputBorder(
      borderRadius: BorderRadius.circular(radii.card),
      borderSide: BorderSide(color: colors.border),
    );

    return Scaffold(
      appBar: AppTopBar(
        kind: AppTopBarKind.sub,
        title: l10n.composerTitle,
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            // Deep-linked with an empty stack: back to the home feed.
            const HomeRoute().go(context);
          }
        },
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: <Widget>[
          Text(
            l10n.composerPhotosLabel(_media.length),
            style: typography.body14.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.text2,
            ),
          ),
          const SizedBox(height: 8),
          if (_media.isEmpty) ...<Widget>[
            _AddZone(
              label: l10n.composerAddPhotos,
              onTap: _posting ? null : _addPhotos,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.composerLimitsHelper,
              style: typography.caption13.copyWith(color: colors.text2),
            ),
          ] else
            LayoutBuilder(
              builder: (context, constraints) {
                // Three-up at the canvas gutter (390: 110px tiles);
                // narrower devices shrink the tile, never the count.
                final tileSize = ((constraints.maxWidth - 2 * _tileGap) / 3)
                    .floorToDouble();
                return Wrap(
                  spacing: _tileGap,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final (index, item) in _media.indexed)
                      _MediaTile(
                        size: tileSize,
                        image: seedMediaImage(item.url),
                        uploading: _posting,
                        uploadingLabel: l10n.composerUploading,
                        removeLabel: l10n.composerRemovePhoto(index + 1),
                        // Null handler while the publish is in flight —
                        // the dot stays painted (frame parity), taps
                        // are ignored.
                        onRemove: _posting
                            ? null
                            : () => setState(() => _media.removeAt(index)),
                      ),
                    if (_media.length < ComposerScreen.maxPhotos)
                      _AddTile(
                        size: tileSize,
                        label: l10n.composerAddPhotos,
                        onTap: _posting ? null : _addPhotos,
                      ),
                  ],
                );
              },
            ),
          const SizedBox(height: 24),
          Text(
            l10n.composerCaptionLabel,
            style: typography.body14.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _caption,
            readOnly: _posting,
            minLines: 2,
            maxLines: 5,
            maxLength: 500,
            style: typography.body14.copyWith(color: colors.text),
            decoration: InputDecoration(
              hintText: l10n.composerCaptionHint,
              hintStyle: typography.body14.copyWith(color: colors.text2),
              isDense: true,
              filled: true,
              fillColor: colors.bgElev,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: inputBorder(),
              enabledBorder: inputBorder(),
              // The DS textarea's 0/500 counter is cropped out of the
              // C15 frames — the limit holds, the counter stays hidden.
              counterText: '',
            ),
          ),
          const SizedBox(height: 24),
          _SnapshotToggleCard(
            title: l10n.composerSnapshotTitle,
            helper: l10n.composerSnapshotHelper,
            value: _attachSnapshot,
            // Locked while in flight: the payload was read at submit —
            // a mid-upload flip would silently not apply.
            onChanged: _posting
                ? null
                : (value) => setState(() => _attachSnapshot = value),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Button(
          label: l10n.composerPost,
          loading: _posting,
          expand: true,
          onPressed: canPost ? _post : null,
        ),
      ),
    );
  }
}

/// The canvas gutter between tiles (390 frame: 110px tiles at 16px
/// margins).
const double _tileGap = 14;

/// The empty-state dashed add-zone (canvas 551:2877): full-width, 120
/// tall, centered plus + label.
class _AddZone extends StatelessWidget {
  const _AddZone({required this.label, required this.onTap});

  final String label;

  /// Null while the publish is in flight — painted the same, taps
  /// ignored (the null-handler prop contract).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;

    return Semantics(
      container: true,
      excludeSemantics: true,
      button: true,
      enabled: onTap != null,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: colors.border,
            radius: radii.card,
          ),
          child: SizedBox(
            height: 120,
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(LucideIcons.plus, size: 24, color: colors.text),
                const SizedBox(height: 14),
                Text(
                  label,
                  style: typography.body14.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.text,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The grid's dashed add-tile (canvas 551:4232): tile-sized, centered
/// plus.
class _AddTile extends StatelessWidget {
  const _AddTile({
    required this.size,
    required this.label,
    required this.onTap,
  });

  final double size;
  final String label;

  /// Null while the publish is in flight (null-handler prop contract).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;

    return Semantics(
      container: true,
      excludeSemantics: true,
      button: true,
      enabled: onTap != null,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: colors.border,
            radius: radii.card,
          ),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(LucideIcons.plus, size: 24, color: colors.text),
          ),
        ),
      ),
    );
  }
}

/// One picked-media tile (canvas 551:4163): the preview at radius 8
/// under a top-right remove dot; the uploading state lays the
/// "Uploading…" strip across the tile's foot (552:2).
class _MediaTile extends StatelessWidget {
  const _MediaTile({
    required this.size,
    required this.image,
    required this.uploading,
    required this.uploadingLabel,
    required this.removeLabel,
    required this.onRemove,
  });

  final double size;
  final ImageProvider<Object> image;
  final bool uploading;
  final String uploadingLabel;
  final String removeLabel;

  /// Null while the publish is in flight — the dot stays painted (frame
  /// parity) but ignores taps (the null-handler prop contract).
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;

    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radii.card),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.bgElev,
                border: Border.all(color: colors.border),
                borderRadius: BorderRadius.circular(radii.card),
              ),
              child: Image(image: image, fit: BoxFit.cover),
            ),
            if (uploading)
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 18,
                  width: double.infinity,
                  color: _onMediaScrim,
                  alignment: Alignment.center,
                  child: Text(
                    uploadingLabel,
                    // Raw white over media — the documented on-media
                    // token exception (design.md; capture chrome
                    // precedent).
                    style: typography.micro12.copyWith(
                      color: const Color(0xFFFFFFFF),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 0,
              right: 0,
              child: Semantics(
                container: true,
                excludeSemantics: true,
                button: true,
                enabled: onRemove != null,
                label: removeLabel,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onRemove,
                  // 4px canvas inset padded out to a sane hit target.
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: _onMediaScrim,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.x,
                        size: 12,
                        // On-media exception (see the strip above).
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The remove dot / uploading strip scrim — an over-media surface, so it
/// stays raw dark ink in both themes (the on-media exception; tokens
/// would invert it off the photograph).
const Color _onMediaScrim = Color(0xCC111111);

/// The snapshot-attach card (canvas 551:4251; ChoiceCard language at
/// radius 12): ruler glyph · title + helper · the DS Switch, ON by
/// default.
class _SnapshotToggleCard extends StatelessWidget {
  const _SnapshotToggleCard({
    required this.title,
    required this.helper,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String helper;
  final bool value;

  /// Null while the publish is in flight — the Switch renders its
  /// disabled state and ignores taps (the null-handler prop contract).
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElev,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(LucideIcons.ruler, size: 24, color: colors.text),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: typography.body14.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  helper,
                  style: typography.caption13.copyWith(color: colors.text2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Semantics(
            label: title,
            child: AppSwitch(value: value, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}

/// 1.5px dashed rounded-rect stroke (the canvas add affordances;
/// Flutter's `Border` can't dash, so the painter walks the rrect path —
/// the EmptyState dashed-ring precedent).
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const dash = 6.0;
    const gap = 4.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.75),
          Radius.circular(radius),
        ),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dash;
        canvas.drawPath(
          metric.extractPath(
            distance,
            next > metric.length ? metric.length : next,
          ),
          paint,
        );
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color || radius != oldDelegate.radius;
}
