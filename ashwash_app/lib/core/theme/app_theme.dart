import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppColors.primary, // #2E8B57 Deep Forest Green
    scaffoldBackgroundColor: AppColors.bgLight, // #F0F8F0 Light Grayish Green
    cardColor: AppColors.cardLight, // #E0EEE0 Pale Green Cards
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary, // #2E8B57 Deep Forest Green
      secondary: AppColors.secondary, // #8FBC8F Sage Green
      tertiary: AppColors.accent, // #DAA520 Goldenrod Accent
      error: AppColors.danger,
      surface: AppColors.cardLight, // #E0EEE0 Pale Green
      background: AppColors.bgLight, // #F0F8F0 Light Grayish Green
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary, // #2E8B57 Deep Forest Green Header
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      actionsIconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.cardLight, // #E0EEE0 Pale Green
      selectedItemColor: AppColors.primary, // #2E8B57 Deep Forest Green
      unselectedItemColor: AppColors.charcoalGray, // #36454F Charcoal Gray
      elevation: 8,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary, // #2E8B57 Deep Forest Green Primary Button
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary, // #2E8B57
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardLight, // #E0EEE0 Pale Green
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppColors.deepForestGreen, // #2E8B57 Primary Deep Forest Green
    scaffoldBackgroundColor: AppColors.darkForestBg, // #1A2B2C Dark Forest Canvas
    cardColor: AppColors.darkForestSurface, // #2C3E3F Dark Forest Surface
    colorScheme: const ColorScheme.dark(
      primary: AppColors.deepForestGreen, // #2E8B57
      secondary: AppColors.sageGreen, // #8FBC8F
      tertiary: AppColors.accentGold, // #DAA520 Accent Gold
      error: AppColors.danger,
      surface: AppColors.darkForestSurface, // #2C3E3F
      background: AppColors.darkForestBg, // #1A2B2C
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.deepForestGreen, // #2E8B57 Header
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.lightText),
      actionsIconTheme: IconThemeData(color: AppColors.lightText),
      titleTextStyle: TextStyle(color: AppColors.lightText, fontSize: 20, fontWeight: FontWeight.bold),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkForestSurface, // #2C3E3F Surface
      selectedItemColor: AppColors.sageGreen, // #8FBC8F
      unselectedItemColor: AppColors.sageGreen, // #8FBC8F
      elevation: 8,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.deepForestGreen, // #2E8B57
        foregroundColor: AppColors.lightText, // #E0EEE0
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.darkForestSurface, // #2C3E3F
        foregroundColor: AppColors.lightText, // #E0EEE0
        side: const BorderSide(color: AppColors.sageGreen, width: 1.5),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkForestSurface, // #2C3E3F Surface
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}


