/// The C8 dispute/decline/quote/ship/confirm sheets (canvas C8-dispute,
/// C8-decline; web sibling `OrderActionSheets.tsx`). Sheets are the armed
/// rung of the danger ladder — their confirm buttons are FILLED
/// destructive and the danger sheets are born DISARMED (CLASS 5: the
/// reason starts null and the destructive CTA stays disabled until one is
/// deliberately picked); the row-level entries on the detail screen stay
/// quiet-danger (ButtonKind.quietDanger).
library;

import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/button.dart';
import 'package:apparule/src/core/ui/sheet.dart';
import 'package:apparule/src/core/utils/parse_amount.dart';
import 'package:apparule/src/features/orders/domain/order.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Dispute reason display copy (order-lifecycle.md §1 reasons).
String disputeReasonLabel(BuildContext context, DisputeReason reason) {
  final l10n = context.l10n;
  return switch (reason) {
    DisputeReason.notReceived => l10n.disputeReasonNotReceived,
    DisputeReason.notAsDescribed => l10n.disputeReasonNotAsDescribed,
    DisputeReason.sizeWrong => l10n.disputeReasonSizeWrong,
    DisputeReason.other => l10n.disputeReasonOther,
  };
}

/// Decline reason display copy (flows/designer.md §2 reasons).
String declineReasonLabel(BuildContext context, DeclineReason reason) {
  final l10n = context.l10n;
  return switch (reason) {
    DeclineReason.workload => l10n.declineReasonWorkload,
    DeclineReason.outOfSpecialty => l10n.declineReasonOutOfSpecialty,
    DeclineReason.budgetTooLow => l10n.declineReasonBudgetTooLow,
    DeclineReason.timelineTooTight => l10n.declineReasonTimelineTooTight,
    DeclineReason.other => l10n.declineReasonOther,
  };
}

/// C8 dispute sheet — resolves with the picked reason + note, or null.
Future<(DisputeReason, String?)?> showDisputeSheet(BuildContext context) {
  return Sheet.show<(DisputeReason, String?)>(
    context,
    title: context.l10n.disputeTitle,
    child: const _DisputeForm(),
  );
}

/// C8 decline sheet (designer) — resolves with the picked reason + the
/// optional note to the customer (D04 — the note rides the repository
/// call, web `DeclineSheet` parity), or null.
Future<(DeclineReason, String?)?> showDeclineSheet(BuildContext context) {
  return Sheet.show<(DeclineReason, String?)>(
    context,
    title: context.l10n.declineTitle,
    child: const _DeclineForm(),
  );
}

/// C8 ship sheet (designer) — resolves with the optional tracking number
/// (D10 — web `ShipSheet` parity; a null record field means "shipped
/// without tracking", a null result means dismissed).
Future<({String? tracking})?> showShipSheet(BuildContext context) {
  return Sheet.show<({String? tracking})>(
    context,
    title: context.l10n.shipSheetTitle,
    child: const _ShipForm(),
  );
}

/// Generic armed confirm (web `ConfirmSheet` parity) — the rung between
/// a quiet(-danger) row and an irreversible transition (D08/D09):
/// confirm-delivery releases the payout, withdraw/reject cancels the
/// order. Resolves true only on the explicit confirm tap.
Future<bool?> showOrderConfirmSheet(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  bool destructive = false,
}) {
  return Sheet.show<bool>(
    context,
    title: title,
    child: _ConfirmForm(
      body: body,
      confirmLabel: confirmLabel,
      destructive: destructive,
    ),
  );
}

/// Designer quote sheet — resolves with (kobo amount, due date), or null.
Future<(int, DateTime)?> showQuoteSheet(
  BuildContext context, {
  int? suggestedCents,
}) {
  return Sheet.show<(int, DateTime)>(
    context,
    title: context.l10n.quoteSheetTitle,
    child: _QuoteForm(suggestedCents: suggestedCents),
  );
}

/// Shared field label style.
Widget _fieldLabel(BuildContext context, String text) {
  final theme = Theme.of(context);
  final colors = theme.extension<AppColors>()!;
  final typography = theme.extension<AppTypography>()!;
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: typography.body14.copyWith(
        fontWeight: FontWeight.w600,
        color: colors.text,
      ),
    ),
  );
}

InputDecoration _fieldDecoration(BuildContext context, {String? hint}) {
  final theme = Theme.of(context);
  final colors = theme.extension<AppColors>()!;
  final radii = theme.extension<AppRadii>()!;
  final typography = theme.extension<AppTypography>()!;
  OutlineInputBorder border() => OutlineInputBorder(
    borderRadius: BorderRadius.circular(radii.card),
    borderSide: BorderSide(color: colors.border),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: typography.body14.copyWith(color: colors.text2),
    isDense: true,
    filled: true,
    fillColor: colors.bg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: border(),
    enabledBorder: border(),
  );
}

/// Reason dropdown shared by the two danger sheets. [value] starts null
/// (CLASS 5: the sheet is born disarmed — no default reason ever lands
/// silently); [hint] renders as the unpicked placeholder.
class _ReasonSelect<T> extends StatelessWidget {
  const _ReasonSelect({
    required this.value,
    required this.values,
    required this.labelOf,
    required this.onChanged,
    required this.hint,
  });

  final T? value;
  final List<T> values;
  final String Function(BuildContext, T) labelOf;
  final ValueChanged<T> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;
    return DropdownButtonFormField<T>(
      initialValue: value,
      // The selected row must clamp, not overflow, at narrow widths.
      isExpanded: true,
      items: <DropdownMenuItem<T>>[
        for (final reason in values)
          DropdownMenuItem<T>(
            value: reason,
            child: Text(
              labelOf(context, reason),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
      style: typography.body14.copyWith(color: colors.text),
      icon: Icon(LucideIcons.chevronDown, size: 18, color: colors.text2),
      dropdownColor: colors.bgElev,
      decoration: _fieldDecoration(context, hint: hint),
    );
  }
}

/// The dashed evidence dropzone (canvas C8-dispute) — a visual
/// affordance; photo evidence upload rides the media wave.
class _EvidenceDropzone extends StatelessWidget {
  const _EvidenceDropzone();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;
    return CustomPaint(
      painter: _DashedRectPainter(color: colors.border, radius: radii.card),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: <Widget>[
            Icon(LucideIcons.upload, size: 24, color: colors.text2),
            const SizedBox(height: 8),
            Text(
              l10n.disputeEvidenceDrop,
              style: typography.body14.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.disputeEvidenceMeta,
              textAlign: TextAlign.center,
              style: typography.micro12.copyWith(color: colors.text2),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  const _DashedRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );
    const dash = 5.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dash),
          paint,
        );
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

class _DisputeForm extends StatefulWidget {
  const _DisputeForm();

  @override
  State<_DisputeForm> createState() => _DisputeFormState();
}

class _DisputeFormState extends State<_DisputeForm> {
  // CLASS 5 (D11): born disarmed — the destructive confirm stays disabled
  // until a reason is deliberately picked (web DisputeSheet parity).
  DisputeReason? _reason;
  final TextEditingController _detail = TextEditingController();

  @override
  void dispose() {
    _detail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _fieldLabel(context, l10n.disputeReasonLabel),
        _ReasonSelect<DisputeReason>(
          value: _reason,
          values: DisputeReason.values,
          labelOf: disputeReasonLabel,
          onChanged: (reason) => setState(() => _reason = reason),
          hint: l10n.disputeReasonPlaceholder,
        ),
        const SizedBox(height: 16),
        _fieldLabel(context, l10n.disputeDetailLabel),
        TextField(
          controller: _detail,
          maxLines: 4,
          maxLength: 500,
          style: typography.body14.copyWith(color: colors.text),
          decoration: _fieldDecoration(context, hint: l10n.disputeDetailHint),
        ),
        const SizedBox(height: 8),
        _fieldLabel(context, l10n.disputeEvidenceLabel),
        const SizedBox(
          width: double.infinity,
          child: _EvidenceDropzone(),
        ),
        const SizedBox(height: 16),
        Button(
          label: l10n.disputeSubmit,
          kind: ButtonKind.destructive,
          expand: true,
          // Arms only once a reason exists — never enabled on frame one.
          onPressed: _reason == null
              ? null
              : () => Navigator.of(context).pop(
                  (
                    _reason!,
                    _detail.text.trim().isEmpty ? null : _detail.text.trim(),
                  ),
                ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.disputeFooter,
          style: typography.caption13.copyWith(color: colors.text2),
        ),
      ],
    );
  }
}

class _DeclineForm extends StatefulWidget {
  const _DeclineForm();

  @override
  State<_DeclineForm> createState() => _DeclineFormState();
}

class _DeclineFormState extends State<_DeclineForm> {
  // CLASS 5 (D12): "reason required" means REQUIRED — no default applies
  // silently; the destructive confirm arms only on a deliberate pick.
  DeclineReason? _reason;
  final TextEditingController _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _fieldLabel(context, l10n.declineReasonLabel),
        _ReasonSelect<DeclineReason>(
          value: _reason,
          values: DeclineReason.values,
          labelOf: declineReasonLabel,
          onChanged: (reason) => setState(() => _reason = reason),
          hint: l10n.declineReasonPlaceholder,
        ),
        const SizedBox(height: 16),
        _fieldLabel(context, l10n.declineNoteLabel),
        TextField(
          controller: _note,
          maxLines: 4,
          maxLength: 500,
          style: typography.body14.copyWith(color: colors.text),
          decoration: _fieldDecoration(context, hint: l10n.declineNoteHint),
        ),
        const SizedBox(height: 8),
        Button(
          label: l10n.declineSubmit,
          kind: ButtonKind.destructive,
          expand: true,
          // D04: the note rides along; D12: disarmed until a reason lands.
          onPressed: _reason == null
              ? null
              : () => Navigator.of(context).pop(
                  (
                    _reason!,
                    _note.text.trim().isEmpty ? null : _note.text.trim(),
                  ),
                ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.declineFooter,
          style: typography.caption13.copyWith(color: colors.text2),
        ),
      ],
    );
  }
}

class _QuoteForm extends StatefulWidget {
  const _QuoteForm({this.suggestedCents});

  final int? suggestedCents;

  @override
  State<_QuoteForm> createState() => _QuoteFormState();
}

class _QuoteFormState extends State<_QuoteForm> {
  late final TextEditingController _price = TextEditingController(
    text: widget.suggestedCents == null
        ? ''
        : (widget.suggestedCents! ~/ 100).toString(),
  );
  DateTime _dueAt = DateTime.now().add(const Duration(days: 14));

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueAt = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;
    // CLASS 8/D05: the shared parser — the sheet's own "45,000" hint
    // format must never disable the CTA.
    final kobo = parseAmountMinor(_price.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _fieldLabel(context, l10n.quotePriceLabel),
        TextField(
          controller: _price,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          style: typography.body14.copyWith(color: colors.text),
          decoration: _fieldDecoration(context, hint: '45,000'),
        ),
        const SizedBox(height: 16),
        _fieldLabel(context, l10n.quoteDueLabel),
        GestureDetector(
          onTap: _pickDate,
          child: InputDecorator(
            decoration: _fieldDecoration(context),
            child: Text(
              '${_dueAt.year}-'
              '${_dueAt.month.toString().padLeft(2, '0')}-'
              '${_dueAt.day.toString().padLeft(2, '0')}',
              style: typography.body14.copyWith(color: colors.text),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Button(
          label: l10n.quoteSubmit,
          expand: true,
          onPressed: kobo == null || kobo <= 0
              ? null
              : () => Navigator.of(context).pop((kobo, _dueAt)),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.quoteFooter,
          style: typography.caption13.copyWith(color: colors.text2),
        ),
      ],
    );
  }
}

/// D10 — the mark-shipped form: one optional tracking field (web
/// `ShipSheet` parity; the CTA is primary, not destructive — shipping is
/// the happy path).
class _ShipForm extends StatefulWidget {
  const _ShipForm();

  @override
  State<_ShipForm> createState() => _ShipFormState();
}

class _ShipFormState extends State<_ShipForm> {
  final TextEditingController _tracking = TextEditingController();

  @override
  void dispose() {
    _tracking.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _fieldLabel(context, l10n.shipTrackingLabel),
        TextField(
          controller: _tracking,
          autocorrect: false,
          style: typography.body14.copyWith(color: colors.text),
          decoration: _fieldDecoration(context, hint: 'GIG-0000-LAG'),
        ),
        const SizedBox(height: 16),
        Button(
          label: l10n.shipSubmit,
          expand: true,
          onPressed: () {
            final tracking = _tracking.text.trim();
            Navigator.of(
              context,
            ).pop((tracking: tracking.isEmpty ? null : tracking));
          },
        ),
        const SizedBox(height: 12),
        Text(
          l10n.shipFooter,
          style: typography.caption13.copyWith(color: colors.text2),
        ),
      ],
    );
  }
}

/// D08/D09 — the generic armed confirm body: explainer copy over a
/// Cancel/confirm pair (web `ConfirmSheet` parity).
class _ConfirmForm extends StatelessWidget {
  const _ConfirmForm({
    required this.body,
    required this.confirmLabel,
    required this.destructive,
  });

  final String body;
  final String confirmLabel;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          body,
          style: typography.body14.copyWith(color: colors.text2),
        ),
        const SizedBox(height: 16),
        Button(
          label: confirmLabel,
          kind: destructive
              ? ButtonKind.destructive
              : ButtonKind.gradientPrimary,
          expand: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: 12),
        Button(
          label: l10n.sheetCancel,
          kind: ButtonKind.quiet,
          expand: true,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}
