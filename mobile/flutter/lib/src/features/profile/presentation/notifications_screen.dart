import 'dart:async';

import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/app_bar.dart';
import 'package:apparule/src/core/ui/avatar.dart';
import 'package:apparule/src/core/ui/caught_up_divider.dart';
import 'package:apparule/src/core/ui/empty_state.dart';
import 'package:apparule/src/core/ui/skeleton.dart';
import 'package:apparule/src/core/utils/clock.dart';
import 'package:apparule/src/core/utils/formats.dart';
import 'package:apparule/src/core/utils/seed_media.dart';
import 'package:apparule/src/features/profile/domain/app_notification.dart';
import 'package:apparule/src/features/profile/presentation/notifications_view_model.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// C10 — the notifications sheet (pages.md: activity list grouped by
/// day, swipe-to-clear). Unread rows tint + dot for THIS visit; opening
/// the screen marks everything read in the repository, so the state
/// persists to the next visit and clears the MI-16 Orders-tab badge.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _markedRead = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(notificationsViewModelProvider);

    // Mark read once the list has loaded — the loaded snapshot keeps its
    // unread tints; the repository (and tab badge) flip immediately.
    if (!_markedRead && state.hasValue) {
      _markedRead = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(
          ref.read(notificationsViewModelProvider.notifier).markAllRead(),
        );
      });
    }

    return Scaffold(
      appBar: AppTopBar(
        kind: AppTopBarKind.sub,
        title: l10n.notificationsTitle,
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            const HomeRoute().go(context);
          }
        },
      ),
      body: switch (state) {
        AsyncData(:final value) => _NotificationsBody(notifications: value),
        AsyncError(:final error) => Center(child: Text('$error')),
        _ => const _NotificationsSkeleton(),
      },
    );
  }
}

/// The C10-loading frame: avatar + line rows.
class _NotificationsSkeleton extends StatelessWidget {
  const _NotificationsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: 6,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: <Widget>[
            Skeleton(kind: SkeletonKind.avatar),
            SizedBox(width: 16),
            Expanded(child: Skeleton()),
          ],
        ),
      ),
    );
  }
}

class _NotificationsBody extends ConsumerWidget {
  const _NotificationsBody({required this.notifications});

  final List<AppNotification> notifications;

  /// Calendar-day grouping: Today · Yesterday · Earlier.
  static String _groupOf(BuildContext context, DateTime at, DateTime now) {
    final l10n = context.l10n;
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(at.year, at.month, at.day);
    final delta = today.difference(day).inDays;
    if (delta <= 0) return l10n.notificationsToday;
    if (delta == 1) return l10n.notificationsYesterday;
    return l10n.notificationsEarlier;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (notifications.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: EmptyState(
            kind: EmptyStateKind.notifications,
            onCta: () {
              if (context.canPop()) {
                context.pop();
              } else {
                const HomeRoute().go(context);
              }
            },
          ),
        ),
      );
    }

    final now = ref.watch(clockProvider)();
    final rows = <Widget>[];
    String? group;
    for (final notification in notifications) {
      final rowGroup = _groupOf(context, notification.createdAt, now);
      if (rowGroup != group) {
        group = rowGroup;
        rows.add(_GroupHeader(label: rowGroup));
      }
      rows.add(_NotificationRow(notification: notification, now: now));
    }
    rows.add(const CaughtUpDivider());
    return ListView(children: rows);
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        label,
        style: typography.body14.copyWith(
          fontWeight: FontWeight.w600,
          color: colors.text,
        ),
      ),
    );
  }
}

class _NotificationRow extends ConsumerWidget {
  const _NotificationRow({required this.notification, required this.now});

  final AppNotification notification;
  final DateTime now;

  void _open(BuildContext context) {
    if (notification.kind.isOrderKind) {
      unawaited(
        OrderDetailRoute(id: notification.payloadRef).push<void>(context),
      );
    } else if (notification.payloadRef.startsWith('post-')) {
      unawaited(
        PostDetailRoute(id: notification.payloadRef).push<void>(context),
      );
    }
    // Follow rows link to the follower's profile — the C9 profile wave.
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;

    // Bold the leading actor username segment (canvas anatomy).
    final text = notification.text;
    final actor = notification.actorUsername;
    final leadsWithActor = text.startsWith(actor);
    final ago = formatAgo(notification.createdAt, now: now);

    return Dismissible(
      key: ValueKey<String>(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => ref
          .read(notificationsViewModelProvider.notifier)
          .clear(notification.id),
      background: Container(
        color: colors.error.withValues(alpha: 0.12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Icon(Icons.delete_outline, color: colors.error),
      ),
      child: Semantics(
        button: true,
        label: '${notification.text}. ${l10n.notificationsClearLabel}',
        child: GestureDetector(
          onTap: () => _open(context),
          child: ColoredBox(
            color: notification.unread
                ? colors.accentStart.withValues(alpha: 0.07)
                : Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 12,
                    child: notification.unread
                        ? Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colors.like,
                              borderRadius: BorderRadius.circular(
                                radii.pill,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 4),
                  Avatar(
                    name: actor,
                    image: seedMediaImageOrNull(notification.actorAvatarUrl),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: <InlineSpan>[
                          if (leadsWithActor) ...<InlineSpan>[
                            TextSpan(
                              text: actor,
                              style: typography.body14.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colors.text,
                              ),
                            ),
                            TextSpan(text: text.substring(actor.length)),
                          ] else
                            TextSpan(text: text),
                          TextSpan(
                            text: '  $ago',
                            style: typography.caption13.copyWith(
                              color: colors.text2,
                            ),
                          ),
                        ],
                      ),
                      style: typography.body14.copyWith(color: colors.text),
                    ),
                  ),
                  if (notification.thumbUrl case final thumb?) ...<Widget>[
                    const SizedBox(width: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(radii.card),
                      child: Image(
                        image: seedMediaImage(thumb),
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
