import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/app_bar.dart';
import 'package:apparule/src/core/ui/app_haptics.dart';
import 'package:apparule/src/core/ui/banner.dart';
import 'package:apparule/src/core/ui/button.dart';
import 'package:apparule/src/core/ui/confetti_burst.dart';
import 'package:apparule/src/core/ui/empty_state.dart';
import 'package:apparule/src/core/ui/status_pill.dart';
import 'package:apparule/src/core/ui/step_slide.dart';
import 'package:apparule/src/core/utils/clock.dart';
import 'package:apparule/src/core/utils/formats.dart';
import 'package:apparule/src/core/utils/parse_amount.dart';
import 'package:apparule/src/features/feed/domain/post.dart';
import 'package:apparule/src/features/measurements/domain/measurement_session.dart';
import 'package:apparule/src/features/measurements/presentation/capture_launcher.dart';
import 'package:apparule/src/features/orders/domain/order.dart';
import 'package:apparule/src/features/orders/domain/order_exception.dart';
import 'package:apparule/src/features/orders/presentation/request_view_model.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Soft warning (web `use-request-stepper.ts` isTurnaroundTight parity):
/// the need-by date lands inside the designer's typical turnaround.
@visibleForTesting
bool turnaroundTight(Post post, DateTime? needBy, DateTime now) {
  if (needBy == null || post.turnaroundDays <= 0) return false;
  return needBy.isBefore(now.add(Duration(days: post.turnaroundDays)));
}

/// C5 — the request stepper (MI-10: 24px step slides, confetti ≤800ms):
/// Step 1 measurement-snapshot picker (vault sessions newest-first
/// preselected, freshness warnings) · Step 2 notes/budget/delivery
/// (pre-filled from the last order, §6.3; Continue gates on the complete
/// six-field delivery set — web REQUIRED_DELIVERY parity) · Step 3
/// review (expandable frozen snapshot) → submit (failure taxonomy per
/// flows/request.md §1) · success (confetti + "View order"). Snapshot
/// values freeze at submit (order-lifecycle.md §1).
class RequestStepperScreen extends ConsumerStatefulWidget {
  const RequestStepperScreen({required this.postId, super.key});

  final String postId;

  @override
  ConsumerState<RequestStepperScreen> createState() =>
      _RequestStepperScreenState();
}

class _RequestStepperScreenState extends ConsumerState<RequestStepperScreen> {
  static const int _steps = 3;

  int _step = 0;

  /// MI-10 (D62): the slide direction — backing up slides in from the
  /// left.
  bool _steppedBack = false;
  String? _sessionId;
  bool _sessionPreselected = false;
  DateTime? _needBy;
  Order? _submitted;
  bool _submitting = false;

  /// D38: the submit failure surfacing as an error banner (flows/
  /// request.md §1 taxonomy — duplicate_request offers "View orders").
  OrderErrorCode? _failure;

  final TextEditingController _notes = TextEditingController();
  final TextEditingController _budget = TextEditingController();
  final TextEditingController _recipient = TextEditingController();
  final TextEditingController _line1 = TextEditingController();
  final TextEditingController _city = TextEditingController();
  final TextEditingController _state = TextEditingController();
  final TextEditingController _country = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  bool _deliveryPrefilled = false;

  @override
  void dispose() {
    for (final controller in <TextEditingController>[
      _notes,
      _budget,
      _recipient,
      _line1,
      _city,
      _state,
      _country,
      _phone,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _prefillDelivery(DeliveryAddress? delivery) {
    if (_deliveryPrefilled || delivery == null) return;
    _deliveryPrefilled = true;
    _recipient.text = delivery.recipientName;
    _line1.text = delivery.line1;
    _city.text = delivery.city;
    _state.text = delivery.state;
    _country.text = delivery.country;
    _phone.text = delivery.phone;
  }

  /// D63 (web parity: `setSelectedSessionId(prev ?? complete[0]?.id)`) —
  /// the newest vault session starts selected; Continue starts ready.
  void _preselectSession(List<MeasurementSession> sessions) {
    if (_sessionPreselected || sessions.isEmpty) return;
    _sessionPreselected = true;
    _sessionId ??= sessions.first.id;
  }

  MeasurementSession? _selectedSession(RequestContext context) {
    for (final session in context.sessions) {
      if (session.id == _sessionId) return session;
    }
    return null;
  }

  /// D14 — the six-field REQUIRED_DELIVERY set (web
  /// `use-request-stepper.ts` parity): Continue stays disabled until a
  /// deliverable address exists; a blank address can never submit.
  bool get _deliveryComplete => <TextEditingController>[
    _recipient,
    _phone,
    _line1,
    _city,
    _state,
    _country,
  ].every((controller) => controller.text.trim().isNotEmpty);

  Future<void> _submit(RequestContext requestContext) async {
    final session = _selectedSession(requestContext);
    if (session == null || _submitting) return;
    setState(() {
      _submitting = true;
      _failure = null;
    });
    try {
      final order = await ref
          .read(requestViewModelProvider(widget.postId).notifier)
          .submit(
            session: session,
            delivery: DeliveryAddress(
              // D15: the recipient the user actually typed — never a
              // hardcoded persona fallback.
              recipientName: _recipient.text.trim(),
              phone: _phone.text.trim(),
              line1: _line1.text.trim(),
              city: _city.text.trim(),
              state: _state.text.trim(),
              country: _country.text.trim(),
            ),
            notes: _notes.text.trim(),
            // CLASS 8: the one shared money parser (with the C8 quote
            // sheet) — grouping/symbols never invalidate a budget.
            budgetCents: parseAmountMinor(_budget.text),
            targetDate: _needBy,
          );
      // MI-20 medium: request submitted.
      AppHaptics.medium();
      setState(() => _submitted = order);
    } on OrderException catch (exception) {
      // D38: the flows/request.md §1 taxonomy surfaces as a banner; the
      // user's whole stepper state survives.
      setState(() => _failure = exception.code);
    } on Object {
      setState(() => _failure = OrderErrorCode.networkFailed);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(requestViewModelProvider(widget.postId));

    if (_submitted case final order?) {
      return _SuccessView(
        order: order,
        designerUsername: order.designer.username,
      );
    }

    return Scaffold(
      appBar: AppTopBar(
        kind: AppTopBarKind.sub,
        title: l10n.requestStepTitle(_step + 1, _steps),
        onBack: () {
          if (_step > 0) {
            _goToStep(_step - 1);
          } else if (context.canPop()) {
            context.pop();
          } else {
            const HomeRoute().go(context);
          }
        },
      ),
      body: switch (state) {
        AsyncData(:final value) => _buildStep(context, value),
        AsyncError(:final error) => Center(child: Text('$error')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  void _goToStep(int step) => setState(() {
    _steppedBack = step < _step;
    _step = step;
  });

  Widget _buildStep(BuildContext context, RequestContext requestContext) {
    _prefillDelivery(requestContext.lastDelivery);
    _preselectSession(requestContext.sessions);
    final session = _selectedSession(requestContext);
    final now = ref.watch(clockProvider)();

    final Widget body;
    final Widget cta;
    final l10n = context.l10n;
    switch (_step) {
      case 0:
        body = _SnapshotStep(
          sessions: requestContext.sessions,
          selectedId: _sessionId,
          onSelect: (id) => setState(() => _sessionId = id),
        );
        cta = Button(
          label: l10n.requestContinue,
          expand: true,
          onPressed: session == null ? null : () => _goToStep(1),
        );
      case 1:
        final budgetKobo = parseAmountMinor(_budget.text);
        final basePrice = requestContext.post.basePriceCents;
        body = _DetailsStep(
          notes: _notes,
          budget: _budget,
          recipient: _recipient,
          line1: _line1,
          city: _city,
          state: _state,
          country: _country,
          phone: _phone,
          needBy: _needBy,
          onNeedBy: (date) => setState(() => _needBy = date),
          // D14/D44: gating and warnings re-derive as the user types.
          onFieldChanged: () => setState(() {}),
          // D44 (web budgetWarning/turnaroundWarning parity): soft
          // warnings — warn, never block.
          budgetBelowBase:
              basePrice != null && budgetKobo != null && budgetKobo < basePrice,
          turnaroundDays: turnaroundTight(requestContext.post, _needBy, now)
              ? requestContext.post.turnaroundDays
              : null,
        );
        cta = Button(
          label: l10n.requestContinue,
          expand: true,
          // D14: a blank address/phone can never advance to submit.
          onPressed: _deliveryComplete ? () => _goToStep(2) : null,
        );
      default:
        body = _ReviewStep(
          requestContext: requestContext,
          session: session,
          needBy: _needBy,
          notes: _notes.text,
          budget: _budget.text,
          line1: _line1.text,
          city: _city.text,
          state: _state.text,
          failure: _failure,
        );
        cta = Button(
          label: l10n.requestSubmit,
          loading: _submitting,
          expand: true,
          onPressed: () => _submit(requestContext),
        );
    }

    return Column(
      children: <Widget>[
        _ProgressTrack(fraction: (_step + 1) / _steps),
        Expanded(
          // MI-10 (D62): step bodies slide 24px through the shared
          // primitive, keyed by step so the switcher sees the swap.
          child: StepSlide(
            reverse: _steppedBack,
            child: KeyedSubtree(
              key: ValueKey<int>(_step),
              child: body,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).extension<AppColors>()!.bg,
          ),
          child: SafeArea(
            top: false,
            child: Padding(padding: const EdgeInsets.all(12), child: cta),
          ),
        ),
      ],
    );
  }
}

/// The MI-10 full-bleed 4px progress track (the Sheet stepper's header
/// geometry on a routed screen).
class _ProgressTrack extends StatelessWidget {
  const _ProgressTrack({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final motion = theme.extension<AppMotion>()!;
    return SizedBox(
      height: 4,
      width: double.infinity,
      child: ColoredBox(
        color: colors.border,
        child: Align(
          alignment: Alignment.centerLeft,
          child: AnimatedFractionallySizedBox(
            duration: motion.slow,
            curve: motion.standardEasing,
            widthFactor: fraction,
            heightFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: colors.accentGradient),
            ),
          ),
        ),
      ),
    );
  }
}

/// Step 1 — the vault snapshot picker (C6/C7 integration): session rows
/// with method chip, value preview, and the freshness ladder.
class _SnapshotStep extends ConsumerWidget {
  const _SnapshotStep({
    required this.sessions,
    required this.selectedId,
    required this.onSelect,
  });

  final List<MeasurementSession> sessions;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  /// The MI-11 freshness ladder (design.md §2): fresh <30d · aging
  /// 30–90d · stale >90d.
  static StatusPillValue _freshnessOf(
    MeasurementSession session,
    DateTime now,
  ) {
    final days = now.difference(session.createdAt).inDays;
    if (days < 30) return StatusPillValue.fresh;
    if (days < 90) return StatusPillValue.aging;
    return StatusPillValue.stale;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;
    final now = ref.watch(clockProvider)();

    if (sessions.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: EmptyState(
            kind: EmptyStateKind.vault,
            line: l10n.requestEmptyVaultLine,
            onCta: () => launchCaptureFlow(context, ref),
          ),
        ),
      );
    }

    MeasurementSession? selected;
    for (final session in sessions) {
      if (session.id == selectedId) selected = session;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(
          l10n.requestStep1Heading,
          style: typography.title20SemiBold.copyWith(color: colors.text),
        ),
        const SizedBox(height: 16),
        for (final session in sessions)
          _SnapshotRow(
            session: session,
            freshness: _freshnessOf(session, now),
            selected: session.id == selectedId,
            onTap: () => onSelect(session.id),
          ),
        if (selected != null &&
            _freshnessOf(selected, now) == StatusPillValue.stale) ...<Widget>[
          const SizedBox(height: 8),
          AppBanner(message: l10n.requestStaleWarning, tone: BannerTone.warn),
        ],
        const SizedBox(height: 16),
        Text(
          l10n.requestSnapshotFrozen,
          style: typography.caption13.copyWith(color: colors.text2),
        ),
      ],
    );
  }
}

class _SnapshotRow extends StatelessWidget {
  const _SnapshotRow({
    required this.session,
    required this.freshness,
    required this.selected,
    required this.onTap,
  });

  final MeasurementSession session;
  final StatusPillValue freshness;
  final bool selected;
  final VoidCallback onTap;

  static String _trim(double value) => value == value.truncateToDouble()
      ? value.truncate().toString()
      : value.toString();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;

    final preview = session.measurements
        .take(2)
        .map(
          (measurement) =>
              '${measurement.name.split('_').first} '
              '${_trim(measurement.valueCm)}',
        )
        .join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.bgElev,
              border: Border.all(
                color: selected ? colors.accentStart : colors.border,
                width: selected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(radii.card),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  selected ? LucideIcons.circleDot : LucideIcons.circle,
                  size: 20,
                  color: selected ? colors.accentStart : colors.border,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              formatMonthDayYear(session.createdAt),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: typography.body14.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colors.text,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            height: 20,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: colors.border.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(
                                radii.pill,
                              ),
                            ),
                            child: Text(
                              session.isManual
                                  ? l10n.vaultSessionManual
                                  : l10n.vaultSessionScan,
                              style: typography.micro12.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colors.text2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.requestSnapshotMeta(
                          session.measurements.length,
                          preview,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: typography.caption13.copyWith(
                          color: colors.text2,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusPill(status: freshness),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Step 2 — notes + budget + need-by + §6.3 delivery pre-fill, with the
/// D44 soft-warning banners and the D14 gating callback.
class _DetailsStep extends StatelessWidget {
  const _DetailsStep({
    required this.notes,
    required this.budget,
    required this.recipient,
    required this.line1,
    required this.city,
    required this.state,
    required this.country,
    required this.phone,
    required this.needBy,
    required this.onNeedBy,
    required this.onFieldChanged,
    required this.budgetBelowBase,
    required this.turnaroundDays,
  });

  final TextEditingController notes;
  final TextEditingController budget;
  final TextEditingController recipient;
  final TextEditingController line1;
  final TextEditingController city;
  final TextEditingController state;
  final TextEditingController country;
  final TextEditingController phone;
  final DateTime? needBy;
  final ValueChanged<DateTime> onNeedBy;

  /// Fires on every keystroke so the parent re-derives Continue gating
  /// (D14) and the budget warning (D44).
  final VoidCallback onFieldChanged;

  /// D44: budget typed below the designer's base price.
  final bool budgetBelowBase;

  /// D44: non-null (the designer's typical days) when the need-by date
  /// is tighter than the turnaround.
  final int? turnaroundDays;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;

    OutlineInputBorder border() => OutlineInputBorder(
      borderRadius: BorderRadius.circular(radii.card),
      borderSide: BorderSide(color: colors.border),
    );

    InputDecoration decoration({String? hint, Widget? suffix}) =>
        InputDecoration(
          hintText: hint,
          hintStyle: typography.body14.copyWith(color: colors.text2),
          isDense: true,
          filled: true,
          fillColor: colors.bgElev,
          suffixIcon: suffix,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: border(),
          enabledBorder: border(),
        );

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        text,
        style: typography.body14.copyWith(
          fontWeight: FontWeight.w600,
          color: colors.text,
        ),
      ),
    );

    final fieldStyle = typography.body14.copyWith(color: colors.text);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: <Widget>[
        label(l10n.requestNotesLabel),
        TextField(
          controller: notes,
          maxLines: 3,
          style: fieldStyle,
          decoration: decoration(hint: l10n.requestNotesHint),
        ),
        label(l10n.requestBudgetLabel),
        TextField(
          controller: budget,
          keyboardType: TextInputType.number,
          onChanged: (_) => onFieldChanged(),
          style: fieldStyle,
          decoration: decoration(
            hint: '₦ 45,000',
            suffix: Padding(
              padding: const EdgeInsets.only(right: 12, top: 12),
              child: Text(
                'NGN',
                style: typography.caption13.copyWith(color: colors.text2),
              ),
            ),
          ),
        ),
        if (budgetBelowBase) ...<Widget>[
          const SizedBox(height: 8),
          AppBanner(
            message: l10n.requestBudgetWarning,
            tone: BannerTone.warn,
          ),
        ],
        label(l10n.requestNeedByLabel),
        GestureDetector(
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: needBy ?? now.add(const Duration(days: 30)),
              firstDate: now,
              lastDate: now.add(const Duration(days: 365)),
            );
            if (picked != null) onNeedBy(picked);
          },
          child: InputDecorator(
            decoration: decoration(),
            child: Row(
              children: <Widget>[
                Icon(LucideIcons.calendar, size: 18, color: colors.text2),
                const SizedBox(width: 8),
                Text(
                  needBy == null
                      ? l10n.requestNeedByHint
                      : formatMonthDayYear(needBy!),
                  style: needBy == null
                      ? fieldStyle.copyWith(color: colors.text2)
                      : fieldStyle,
                ),
              ],
            ),
          ),
        ),
        if (turnaroundDays case final days?) ...<Widget>[
          const SizedBox(height: 8),
          AppBanner(
            message: l10n.requestTurnaroundWarning(days),
            tone: BannerTone.warn,
          ),
        ],
        label(l10n.requestDeliveryHeading),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.bgElev,
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(radii.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // D15: recipient name is part of the web REQUIRED_DELIVERY
              // set — an order must never ship addressed to a hardcoded
              // persona.
              for (final (fieldLabel, controller)
                  in <(String, TextEditingController)>[
                    (l10n.requestRecipientName, recipient),
                    (l10n.requestAddressLine1, line1),
                    (l10n.requestCity, city),
                    (l10n.requestState, state),
                    (l10n.requestCountry, country),
                    (l10n.requestPhone, phone),
                  ]) ...<Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    fieldLabel,
                    style: typography.caption13.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.text,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextField(
                    controller: controller,
                    onChanged: (_) => onFieldChanged(),
                    style: fieldStyle,
                    decoration: decoration(),
                  ),
                ),
              ],
              Text(
                l10n.requestDeliveryFooter,
                style: typography.micro12.copyWith(color: colors.text2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Step 3 — review card + budget card (canvas C5-step3), the D38 failure
/// banner, and the D65 expandable frozen-snapshot values.
class _ReviewStep extends StatefulWidget {
  const _ReviewStep({
    required this.requestContext,
    required this.session,
    required this.needBy,
    required this.notes,
    required this.budget,
    required this.line1,
    required this.city,
    required this.state,
    required this.failure,
  });

  final RequestContext requestContext;
  final MeasurementSession? session;
  final DateTime? needBy;
  final String notes;
  final String budget;
  final String line1;
  final String city;
  final String state;
  final OrderErrorCode? failure;

  @override
  State<_ReviewStep> createState() => _ReviewStepState();
}

class _ReviewStepState extends State<_ReviewStep> {
  /// D65: the frozen values expand for inspection before submit.
  bool _snapshotOpen = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;
    final post = widget.requestContext.post;
    final session = widget.session;
    final needBy = widget.needBy;
    final notes = widget.notes;
    final budgetKobo = parseAmountMinor(widget.budget);

    Widget reviewRow(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: typography.caption13.copyWith(color: colors.text2),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: typography.body14.copyWith(color: colors.text),
            ),
          ),
        ],
      ),
    );

    BoxDecoration card() => BoxDecoration(
      color: colors.bgElev,
      border: Border.all(color: colors.border),
      borderRadius: BorderRadius.circular(radii.card),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(
          l10n.requestStep3Heading,
          style: typography.title20SemiBold.copyWith(color: colors.text),
        ),
        const SizedBox(height: 16),
        // D38: submit failures land here as a banner (web RequestStepper
        // parity) — duplicate_request offers the jump to C8.
        if (widget.failure case final failure?) ...<Widget>[
          AppBanner(
            message: switch (failure) {
              OrderErrorCode.duplicateRequest => l10n.requestDuplicateFailed,
              OrderErrorCode.snapshotInvalid ||
              OrderErrorCode.networkFailed => l10n.requestSubmitFailed,
            },
            tone: BannerTone.error,
            actionLabel: failure == OrderErrorCode.duplicateRequest
                ? l10n.requestViewOrders
                : null,
            onAction: failure == OrderErrorCode.duplicateRequest
                ? () => const OrdersRoute().go(context)
                : null,
          ),
          const SizedBox(height: 16),
        ],
        Container(
          padding: const EdgeInsets.all(16),
          decoration: card(),
          child: Column(
            children: <Widget>[
              reviewRow(
                l10n.requestReviewOutfit,
                l10n.requestOutfitByDesigner(
                  post.caption.split(' — ').first,
                  post.designer.username,
                ),
              ),
              if (session case final session?)
                reviewRow(
                  l10n.requestReviewSnapshot,
                  l10n.requestSnapshotSummary(
                    formatDayMonth(session.createdAt),
                    session.isManual
                        ? l10n.vaultSessionManual.toLowerCase()
                        : l10n.vaultSessionScan.toLowerCase(),
                    session.measurements.length,
                  ),
                ),
              reviewRow(
                l10n.requestReviewDelivery,
                <String>[
                  widget.line1,
                  widget.city,
                  widget.state,
                ].where((part) => part.trim().isNotEmpty).join(', '),
              ),
              reviewRow(
                l10n.requestReviewNeedBy,
                needBy == null ? '—' : formatMonthDayYear(needBy),
              ),
              reviewRow(
                l10n.requestReviewNotes,
                notes.trim().isEmpty ? '—' : notes.trim(),
              ),
            ],
          ),
        ),
        // D65 (web parity: the aria-expanded snapshot section): every
        // value about to freeze is inspectable before submit.
        if (session case final session?) ...<Widget>[
          const SizedBox(height: 16),
          Container(
            decoration: card(),
            child: Column(
              children: <Widget>[
                Semantics(
                  button: true,
                  expanded: _snapshotOpen,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _snapshotOpen = !_snapshotOpen),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              l10n.requestSnapshotValues(
                                session.measurements.length,
                              ),
                              style: typography.body14.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colors.text,
                              ),
                            ),
                          ),
                          Icon(
                            _snapshotOpen
                                ? LucideIcons.chevronUp
                                : LucideIcons.chevronDown,
                            size: 20,
                            color: colors.text2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_snapshotOpen)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      children: <Widget>[
                        for (final measurement in session.measurements)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    humanizeMeasureName(measurement.name),
                                    style: typography.body14.copyWith(
                                      color: colors.text2,
                                    ),
                                  ),
                                ),
                                Text(
                                  formatCm(measurement.valueCm),
                                  style: typography.body14.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colors.text,
                                    fontFeatures: const <FontFeature>[
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: card(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.requestReviewBudget(
                  budgetKobo == null ? '—' : formatNaira(budgetKobo),
                ),
                style: typography.body16SemiBold.copyWith(
                  color: colors.text,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.requestBudgetExplainer,
                style: typography.caption13.copyWith(color: colors.text2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The success frame (canvas C5-success): confetti scatter, check,
/// "Request sent", View order / Back to feed.
class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.order, required this.designerUsername});

  final Order order;
  final String designerUsername;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              const Spacer(),
              SizedBox(
                height: 220,
                width: double.infinity,
                // MI-10: the ≤800ms burst animates once per order and
                // settles on the canvas frame's static scatter.
                child: ConfettiBurst(
                  colors: <Color>[
                    colors.accentStart,
                    colors.accentEnd,
                    colors.success,
                    colors.warn,
                  ],
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Icon(
                      LucideIcons.check,
                      size: 48,
                      color: colors.success,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.requestSuccessTitle,
                style: typography.title24Bold.copyWith(color: colors.text),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.requestSuccessBody(designerUsername),
                textAlign: TextAlign.center,
                style: typography.body14.copyWith(color: colors.text2),
              ),
              const Spacer(),
              Button(
                label: l10n.requestViewOrder,
                expand: true,
                onPressed: () =>
                    OrderDetailRoute(id: order.id).pushReplacement(context),
              ),
              const SizedBox(height: 12),
              Button(
                label: l10n.requestBackToFeed,
                kind: ButtonKind.quiet,
                expand: true,
                onPressed: () => const HomeRoute().go(context),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
