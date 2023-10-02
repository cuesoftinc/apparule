import 'package:flutter/material.dart';

Map<int, Color> color = {
  50: Color.fromARGB(255,118,142,126),
  100: Color.fromARGB(255,118,142,126),
  200: Color.fromARGB(255,118,142,126),
  300: Color.fromARGB(255,118,142,126),
  400: Color.fromARGB(255,118,142,126),
  500: Color.fromARGB(255,118,142,126),
  600: Color.fromARGB(255,118,142,126),
  700: Color.fromARGB(255,118,142,126),
  800: Color.fromARGB(255,118,142,126),
  900: Color.fromARGB(255,118,142,126),
};
MaterialColor colorCustom = MaterialColor(0xff768e7e, color);

ThemeData lightTheme = ThemeData(
  primarySwatch: colorCustom,
  colorScheme: const ColorScheme.light(
      primary: const Color.fromARGB(255,118,142,126),
      background: Color.fromARGB(255, 255, 255, 255),
      onBackground: Color.fromARGB(255, 0, 0, 0),
      secondary: Color.fromARGB(255, 141, 144, 151)),
  canvasColor: const Color.fromARGB(255, 255, 255, 255),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(
      color: Color.fromARGB(255, 0, 0, 0),
      fontSize: null,
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.normal,
    ),
  ),
  hintColor: const Color.fromARGB(255, 141, 144, 151),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: MaterialStateProperty.all<Color>(
        Colors.deepPurple,
      ), //button color
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white), //button color
);
