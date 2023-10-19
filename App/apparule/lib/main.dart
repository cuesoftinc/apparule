import 'package:apparule/language_constants.dart';
import 'package:apparule/persistence.dart';
import 'package:apparule/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dark_theme.dart';
import 'light_theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Persistence.initPersistence();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  static late ValueNotifier<ThemeMode> themeNotifier;

  const MyApp({Key? key}) : super(key: key);


  @override
  _MyAppFieldState createState() => _MyAppFieldState();

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppFieldState? state = context.findAncestorStateOfType<_MyAppFieldState>();
        state?.setLocale(newLocale);
  }
}

class _MyAppFieldState extends State<MyApp> with WidgetsBindingObserver {
  Locale? _locale;

  setLocale(Locale locale){
    setState(() {
      _locale = locale;
    });
  }

  @override
  void initState() {
    var saved = Persistence.isDarkTheme();
    MyApp.themeNotifier = ValueNotifier(
        saved ? ThemeMode.dark : ThemeMode.light
    );
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }


  @override
  void didChangeDependencies()  {
    getLocale().then((locale) => setLocale(locale));
    super.didChangeDependencies();
  }


  @override
  void didChangePlatformBrightness() async {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    super.didChangePlatformBrightness();
    var brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    if (brightness == Brightness.light) {
      MyApp.themeNotifier.value = ThemeMode.light;
      prefs.setBool('isDark', false);
    } else {
      MyApp.themeNotifier.value = ThemeMode.dark;
      prefs.setBool('isDark', true);
    }
  }


    @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
        valueListenable: MyApp.themeNotifier,
        builder: (_, ThemeMode currentMode, __) {
          return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Apparule',
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: currentMode,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: _locale,
              home: SplashScreen());
        });
  }
}
