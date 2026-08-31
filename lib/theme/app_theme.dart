import 'package:flutter/material.dart';

class AppTheme {
  static const Color darkPrimary = Color(0xFF0A2314);
  static const Color darkPrimaryLight = Color(0xFF1E4226);
  static const Color accentGold = Color(0xFFF7DE9B);
  static const Color accentGoldDark = Color(0xFFD4A373);
  static const Color darkTextSecondary = Color(0xFFA0B3A6);

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: darkPrimary,
    scaffoldBackgroundColor: darkPrimary,
    colorScheme: const ColorScheme.dark(
      primary: accentGold,
      secondary: accentGoldDark,
      surface: darkPrimaryLight,
      onPrimary: darkPrimary,
      onSecondary: darkPrimary,
      onSurface: Colors.white,
      outline: darkTextSecondary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkPrimary,
      foregroundColor: accentGold,
      elevation: 0,
      iconTheme: IconThemeData(color: accentGold),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: darkPrimary,
      indicatorColor: accentGold.withValues(alpha: 0.2),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            color: accentGold,
            fontWeight: FontWeight.bold,
          );
        }
        return const TextStyle(color: darkTextSecondary);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: accentGold);
        }
        return const IconThemeData(color: darkTextSecondary);
      }),
    ),
    cardTheme: CardThemeData(
      color: darkPrimaryLight,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentGold,
        foregroundColor: darkPrimary,
      ),
    ),
  );

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: darkPrimary,
    scaffoldBackgroundColor: const Color(0xFFF5F7F5),
    colorScheme: const ColorScheme.light(
      primary: darkPrimary,
      secondary: accentGoldDark,
      surface: Colors.white,
      onPrimary: accentGold,
      onSecondary: Colors.white,
      onSurface: Colors.black87,
      outline: Colors.black26,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkPrimary,
      foregroundColor: accentGold,
      elevation: 0,
      iconTheme: IconThemeData(color: accentGold),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: darkPrimary.withValues(alpha: 0.1),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            color: darkPrimary,
            fontWeight: FontWeight.bold,
          );
        }
        return const TextStyle(color: Colors.black54);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: darkPrimary);
        }
        return const IconThemeData(color: Colors.black54);
      }),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkPrimary,
        foregroundColor: accentGold,
      ),
    ),
  );
}
