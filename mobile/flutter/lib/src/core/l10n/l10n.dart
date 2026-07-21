import 'package:apparule/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';

export 'package:apparule/l10n/generated/app_localizations.dart';

/// `context.l10n` shorthand — the one l10n lookup the tree uses.
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
