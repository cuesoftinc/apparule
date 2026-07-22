/// The C8 dispute/decline/quote sheets (canvas C8-dispute, C8-decline).
/// Sheets are the armed rung of the danger ladder — their confirm
/// buttons are FILLED destructive; the row-level entries on the detail
/// screen stay quiet-danger (ButtonKind.quietDanger).
library;

import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/button.dart';
import 'package:apparule/src/core/ui/sheet.dart';
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

/// C8 decline sheet (designer) — resolves with the reason, or null.
Future<DeclineReason?> showDeclineSheet(BuildContext context) {
  return Sheet.show<DeclineReason>(
    context,
    title: context.l10n.declineTitle,
    child: const _DeclineForm(),
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

/// Reason dropdown shared by the two danger sheets.
class _ReasonSelect<T> extends StatelessWidget {
  const _ReasonSelect({
    required this.value,
    required this.values,
    required this.labelOf,
    required this.onChanged,
  });

  final T value;
  final List<T> values;
  final String Function(BuildContext, T) labelOf;
  final ValueChanged<T> onChanged;

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
      decoration: _fieldDecoration(context),
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
  DisputeReason _reason = DisputeReason.sizeWrong;
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
        ),
        const SizedBox(height: 16),
        _fieldLabel(context, l10n.disputeDetailLabel),
        TextField(
          controller: _detail,
          maxLines: 4,
          maxLength: 500,
          style: typography.body14.copyWith(color: colors.text),
          decoration: _fieldDecoration(context),
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
          onPressed: () => Navigator.of(context).pop(
            (
              _reason,
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
  DeclineReason _reason = DeclineReason.workload;
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
          onPressed: () => Navigator.of(context).pop(_reason),
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
    final naira = int.tryParse(_price.text.trim());

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
          onPressed: naira == null || naira <= 0
              ? null
              : () => Navigator.of(context).pop((naira * 100, _dueAt)),
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
