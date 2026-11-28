import 'package:apparule/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

export 'package:apparule/l10n/generated/app_localizations.dart';

/// App strings plus material_ui's Material, Cupertino and Widgets strings.
const List<LocalizationsDelegate<dynamic>> appLocalizationsDelegates =
    <LocalizationsDelegate<dynamic>>[
      AppLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ];

/// `context.l10n` shorthand — the one l10n lookup the tree uses.
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
