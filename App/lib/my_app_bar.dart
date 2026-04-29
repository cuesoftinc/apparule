import 'package:apparule/language_constants.dart';
import 'package:apparule/persistence.dart';
import 'package:flutter/material.dart';
import 'language.dart';
import 'main.dart';
import 'my_back_button.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MyAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      automaticallyImplyLeading: false,
      leadingWidth: 85,
      backgroundColor: Theme.of(context).primaryColor,
      leading: const MyBackButton(),
      toolbarHeight: 80,
      actions: [
        SizedBox(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
            child: DropdownButton<Language>(
              underline: const SizedBox(),
              icon: const Icon(
                Icons.language,
                color: Colors.white,
              ),
              onChanged: (Language? language) async {
                if (language != null) {
                  Locale _locale = await setLocale(language.languageCode);
                  MyApp.setLocale(context, _locale);
                }
              },
              items: Language.languageList()
                  .map<DropdownMenuItem<Language>>(
                    (e) => DropdownMenuItem<Language>(
                      value: e,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            e.flag,
                            style: const TextStyle(fontSize: 30),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        IconButton(
            icon: Icon(MyApp.themeNotifier.value == ThemeMode.light ? Icons.dark_mode : Icons.light_mode),
            onPressed: () {
              var isDark = MyApp.themeNotifier.value == ThemeMode.dark;
              if (isDark) {
                MyApp.themeNotifier.value = ThemeMode.light;
                Persistence.saveDarkTheme(false);
              } else {
                MyApp.themeNotifier.value = ThemeMode.dark;
                Persistence.saveDarkTheme(false);
              }
            }),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}
