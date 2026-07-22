import 'dart:async' show unawaited;

import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/action_row.dart';
import 'package:apparule/src/core/ui/app_haptics.dart';
import 'package:apparule/src/core/ui/avatar.dart';
import 'package:apparule/src/core/ui/button.dart';
import 'package:apparule/src/core/ui/skeleton.dart';
import 'package:flutter/gestures.dart' show TapGestureRecognizer;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderProxyBox;
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// PostCard — the Figma `PostCard` set (52:462); web sibling
/// `PostCard.tsx`. Axes: `media` single/carousel (dots) · `cta`
/// true/false ("Request this outfit") · `state` default/skeleton.
/// Anatomy (design.md §3): header (avatar, username, badge, ⋯) · media
/// carousel (MI-4) · action row (MI-1/2/3) · like count · caption (2-line
/// clamp, "more") · request CTA · timestamp. MI-1: double-tap media →
/// 96px heart burst + like.
///
/// DS-purity: the module takes plain values (no feature domain types);
/// the timestamp arrives pre-formatted ([timestampLabel]) so the consumer
/// owns the social relative date idiom ("2h" — fleet adjudication).
class PostCard extends StatefulWidget {
  const PostCard({
    required this.username,
    required this.media,
    required this.liked,
    required this.saved,
    required this.likeCount,
    required this.caption,
    this.avatarImage,
    this.verified = false,
    this.commentCount = 0,
    this.timestampLabel,
    this.skeleton = false,
    this.onToggleLike,
    this.onToggleSave,
    this.onRequest,
    this.onComment,
    this.onShare,
    this.onOverflow,
    this.onProfileTap,
    super.key,
  });

  final String username;
  final ImageProvider<Object>? avatarImage;
  final bool verified;

  /// Media pages — length > 1 renders the `carousel` variant (count pill +
  /// dots).
  final List<ImageProvider<Object>> media;

  final bool liked;
  final bool saved;
  final int likeCount;
  final int commentCount;
  final String caption;

  /// Pre-formatted relative timestamp ("2h" idiom).
  final String? timestampLabel;

  /// The `state` axis — `true` renders the §3 skeleton anatomy (MI-19).
  final bool skeleton;

  final VoidCallback? onToggleLike;
  final VoidCallback? onToggleSave;

  /// The `cta` axis — non-null renders the full-width quiet
  /// "Request this outfit" button.
  final VoidCallback? onRequest;

  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onOverflow;

  /// Designer-identity tap — the header (avatar + username) and the
  /// caption's leading username open the designer's profile (web
  /// PostDetailView parity: both link `/dashboard/{username}`).
  final VoidCallback? onProfileTap;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  int _slide = 0;
  bool _bigHeart = false;
  bool _captionOpen = false;

  void _handleDoubleTap() {
    // MI-1: double-tap to like — heart burst + fill + light haptic; the
    // accessible like path stays the ActionRow heart (the media zone is
    // a gesture zone, not a control).
    if (!widget.liked) {
      widget.onToggleLike?.call();
      AppHaptics.light();
    }
    setState(() => _bigHeart = true);
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _bigHeart = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.skeleton) return const Skeleton(kind: SkeletonKind.card);

    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;

    final media = widget.media;
    final carousel = media.length > 1;
    final slide = _slide.clamp(0, media.length - 1);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bg,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Header — Figma master: px 12 / py 8 / gap 8.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _HeaderIdentity(
                      username: widget.username,
                      avatarImage: widget.avatarImage,
                      verified: widget.verified,
                      onTap: widget.onProfileTap,
                    ),
                  ),
                  Semantics(
                    label: 'More options',
                    button: true,
                    child: InkResponse(
                      onTap: widget.onOverflow,
                      radius: 18,
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: Icon(
                          LucideIcons.ellipsis,
                          size: 24,
                          color: colors.text,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Media — full-bleed square; the MI-1 double-tap gesture zone.
            GestureDetector(
              onDoubleTap: _handleDoubleTap,
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    ColoredBox(color: colors.border.withValues(alpha: 0.3)),
                    if (carousel)
                      _ZeroIntrinsics(
                        child: PageView(
                          onPageChanged: (index) =>
                              setState(() => _slide = index),
                          children: <Widget>[
                            for (final provider in media)
                              Image(image: provider, fit: BoxFit.cover),
                          ],
                        ),
                      )
                    else if (media.isNotEmpty)
                      Image(image: media[slide], fit: BoxFit.cover),
                    if (_bigHeart)
                      const Center(
                        // MI-1 heart burst — on-media white by design.
                        child: Icon(
                          Icons.favorite,
                          size: 96,
                          color: Color(0xFFFFFFFF),
                          shadows: <Shadow>[
                            Shadow(blurRadius: 12, color: Color(0x66000000)),
                          ],
                        ),
                      ),
                    if (carousel)
                      Positioned(
                        // MI-4 count pill (Figma 52:368) — inverse surface.
                        top: 12,
                        right: 12,
                        child: Container(
                          height: 22,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: colors.text,
                            borderRadius: BorderRadius.circular(radii.pill),
                          ),
                          child: Text(
                            '${slide + 1}/${media.length}',
                            style: typography.micro12.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colors.bg,
                              fontFeatures: const <FontFeature>[
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Figma master: progress dots sit below the media, not over it.
            if (carousel)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    for (var i = 0; i < media.length; i++)
                      Container(
                        width: i == slide ? 6 : 4,
                        height: i == slide ? 6 : 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: i == slide ? colors.accentGradient : null,
                          color: i == slide ? null : colors.border,
                        ),
                      ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(left: 6, top: 4),
              child: ActionRow(
                liked: widget.liked,
                saved: widget.saved,
                likeCount: widget.likeCount,
                onToggleLike: () => widget.onToggleLike?.call(),
                onToggleSave: () => widget.onToggleSave?.call(),
                onComment: widget.onComment,
                onShare: widget.onShare,
              ),
            ),
            // Like count + caption + comments + CTA + timestamp — one
            // px-16 column at 4px rhythm.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${_groupedCount(widget.likeCount)} likes',
                    style: typography.body14.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.text,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  _Caption(
                    username: widget.username,
                    caption: widget.caption,
                    open: _captionOpen,
                    onMore: () => setState(() => _captionOpen = true),
                    onUsernameTap: widget.onProfileTap,
                  ),
                  if (widget.commentCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: GestureDetector(
                        onTap: widget.onComment,
                        child: Text(
                          'View all ${widget.commentCount} comments',
                          style: typography.body14.copyWith(
                            color: colors.text2,
                          ),
                        ),
                      ),
                    ),
                  if (widget.onRequest != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Button(
                        label: 'Request this outfit',
                        kind: ButtonKind.quiet,
                        onPressed: widget.onRequest,
                        expand: true,
                      ),
                    ),
                  if (widget.timestampLabel != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        widget.timestampLabel!.toUpperCase(),
                        style: typography.micro12.copyWith(
                          letterSpacing: 0.4,
                          color: colors.text2,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _groupedCount(int value) {
    final digits = value.toString();
    final grouped = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) grouped.write(',');
      grouped.write(digits[i]);
    }
    return grouped.toString();
  }
}

/// The tappable header identity — avatar + username as ONE profile
/// affordance (the user-reported live-QA defect: neither navigated).
/// Layout matches the previous inline anatomy exactly; the tap layer is
/// behavior-only, so goldens hold.
class _HeaderIdentity extends StatelessWidget {
  const _HeaderIdentity({
    required this.username,
    required this.avatarImage,
    required this.verified,
    required this.onTap,
  });

  final String username;
  final ImageProvider<Object>? avatarImage;
  final bool verified;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;

    final identity = Row(
      children: <Widget>[
        Avatar(
          name: username,
          size: AvatarSize.s32,
          image: avatarImage,
          badge: verified ? AvatarBadge.designerVerified : AvatarBadge.none,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            username,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typography.body14.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.text,
            ),
          ),
        ),
      ],
    );

    // No destination, no control — never announce a dead button
    // (skeleton hosts, previews).
    if (onTap == null) return identity;

    return Semantics(
      // One node announcing the affordance once (the StoryRailItem
      // pattern) — the inner username text is visual.
      container: true,
      excludeSemantics: true,
      label: 'View $username profile',
      button: true,
      onTap: onTap,
      child: InkWell(onTap: onTap, child: identity),
    );
  }
}

class _Caption extends StatefulWidget {
  const _Caption({
    required this.username,
    required this.caption,
    required this.open,
    required this.onMore,
    required this.onUsernameTap,
  });

  final String username;
  final String caption;
  final bool open;
  final VoidCallback onMore;

  /// Web PostDetailView parity: the caption's leading username links the
  /// designer profile.
  final VoidCallback? onUsernameTap;

  @override
  State<_Caption> createState() => _CaptionState();
}

class _CaptionState extends State<_Caption> {
  // Span recognizers are owned (and disposed) here — a build-scoped
  // recognizer would leak its gesture arena entry.
  final TapGestureRecognizer _usernameRecognizer = TapGestureRecognizer();

  @override
  void initState() {
    super.initState();
    _usernameRecognizer.onTap = () => widget.onUsernameTap?.call();
  }

  @override
  void dispose() {
    _usernameRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;

    final style = typography.body14.copyWith(
      fontWeight: FontWeight.w600,
      color: colors.text,
    );
    final showMore = !widget.open && widget.caption.length > 80;
    final linkedUsername = widget.onUsernameTap != null;

    return GestureDetector(
      onTap: showMore ? widget.onMore : null,
      child: Text.rich(
        TextSpan(
          children: <InlineSpan>[
            TextSpan(
              text: '${widget.username} ',
              recognizer: linkedUsername ? _usernameRecognizer : null,
              semanticsLabel: linkedUsername
                  ? 'View ${widget.username} profile'
                  : null,
            ),
            TextSpan(text: widget.caption),
            if (showMore)
              TextSpan(
                text: ' more',
                style: style.copyWith(
                  fontWeight: FontWeight.w400,
                  color: colors.text2,
                ),
              ),
          ],
        ),
        style: style,
        maxLines: widget.open ? null : 2,
        overflow: widget.open ? TextOverflow.visible : TextOverflow.ellipsis,
      ),
    );
  }
}

/// Shields the carousel's [PageView] from intrinsic-dimension queries —
/// viewports cannot answer them (they would have to instantiate every
/// lazy child), which breaks intrinsics-driven hosts (tables, golden
/// grids). The media zone's size always comes from the enclosing
/// [AspectRatio], so the honest intrinsic contribution is zero.
class _ZeroIntrinsics extends SingleChildRenderObjectWidget {
  const _ZeroIntrinsics({required Widget super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderZeroIntrinsics();
}

class _RenderZeroIntrinsics extends RenderProxyBox {
  @override
  double computeMinIntrinsicWidth(double height) => 0;

  @override
  double computeMaxIntrinsicWidth(double height) => 0;

  @override
  double computeMinIntrinsicHeight(double width) => 0;

  @override
  double computeMaxIntrinsicHeight(double width) => 0;
}
