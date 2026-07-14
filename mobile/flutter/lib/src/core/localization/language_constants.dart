import 'package:apparule/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String LAGUAGE_CODE = 'languageCode';
const String ENGLISH = 'en';
const String SHQIP = 'sq';

Future<Locale> setLocale(String languageCode) async {
  SharedPreferences _prefs = await SharedPreferences.getInstance();
  await _prefs.setString(LAGUAGE_CODE, languageCode);
  return _locale(languageCode);
}

Future<Locale> getLocale() async {
  SharedPreferences _prefs = await SharedPreferences.getInstance();
  String languageCode = _prefs.getString(LAGUAGE_CODE) ?? ENGLISH;
  return _locale(languageCode);
}

Locale _locale(String languageCode) {
  switch (languageCode) {
    case ENGLISH:
      return const Locale(ENGLISH, '');
    case SHQIP:
      return const Locale(SHQIP, "");
    default:
      return const Locale(ENGLISH, '');
  }
}

// Translation helper backed by the generated localizations (lib/l10n).
AppLocalizations translation(BuildContext context) {
  return AppLocalizations.of(context)!;
}
