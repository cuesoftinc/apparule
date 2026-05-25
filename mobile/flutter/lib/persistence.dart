
import 'package:shared_preferences/shared_preferences.dart';

import 'model/user.dart';

SharedPreferences? _prefs;

class Persistence {

  static Future<void> initPersistence() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static void saveUser(User user) {
    _prefs?.setString("email", user.email ?? "");
    _prefs?.setString("name", user.name ?? "");
    _prefs?.setString("phone", user.phoneNumber ?? "");
  }

  static User? getUser() {
    if (_prefs?.getString("name") == null) {
      return null;
    }
    return User(
        email:  _prefs!.getString("email") ?? "",
        name:  _prefs!.getString("name") ?? "",
        phoneNumber:  _prefs!.getString("phone") ?? "",
    );

  }

  static void deleteUser() {
    _prefs?.remove("email");
    _prefs?.remove("name");
    _prefs?.remove("phone");
  }

  static bool isDarkTheme() => _prefs?.getBool('isDark') ?? false;
  static void saveDarkTheme(bool isDarkTheme) => _prefs?.setBool('isDark', isDarkTheme);
}

