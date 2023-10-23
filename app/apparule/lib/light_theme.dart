import 'package:flutter/material.dart';

Map<int, Color> color = {
  50: Color.fromARGB(255,21,10,50),
  100: Color.fromARGB(255,21,10,50),
  200: Color.fromARGB(255,21,10,50),
  300: Color.fromARGB(255,21,10,50),
  400: Color.fromARGB(255,21,10,50),
  500: Color.fromARGB(255,21,10,50),
  600: Color.fromARGB(255,21,10,50),
  700: Color.fromARGB(255,21,10,50),
  800: Color.fromARGB(255,21,10,50),
  900: Color.fromARGB(255,21,10,50),
};
MaterialColor colorCustom = MaterialColor(0xFF150A32, color);

ThemeData lightTheme = ThemeData(
  primarySwatch: colorCustom,
  colorScheme: ColorScheme.light(
      primary: Color.fromARGB(255, 21, 10, 50),
      background: Color.fromARGB(255, 21, 10, 50),
      onBackground: Color.fromARGB(255, 255, 255, 255),
      secondary: Color.fromARGB(255, 18, 33, 72),
      tertiary: Color.fromARGB(255, 0, 113, 254)
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(
      color: Color.fromARGB(255, 255, 255, 255),
      fontSize: null,
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.normal,
    ),
  ),
  hintColor: const Color.fromARGB(255, 181, 181, 181),
);
