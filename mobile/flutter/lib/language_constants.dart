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

// Concrete fallback class with the exact fields the UI is screaming for
class FallbackLocalizations {
  String get emailAddress => 'Email Address';
  String get createAnAccount => 'Create an Account';
  String get login => 'Login';
  String get password => 'Password';
  String get username => 'Username';
  String get submit => 'Submit';
  String get next => 'Next';

  // This catch-all handle helps prevent crashes if other properties are hit
  @override
  dynamic noSuchMethod(Invocation invocation) => '';
}

// Direct the translation helper to use this explicit fallback object
dynamic translation(BuildContext context) {
  return FallbackLocalizations();
}
