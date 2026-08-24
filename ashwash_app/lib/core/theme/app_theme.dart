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
    primaryColor: AppColors.primary, // #4E1F6E Deep Purple
    scaffoldBackgroundColor: AppColors.lightMint, // #98E8DE Light Mint Background
    cardColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary, // #4E1F6E Deep Purple
      secondary: AppColors.secondary, // #3E3E75 Dark Indigo
      tertiary: AppColors.accent, // #45A9A9 Teal
      error: AppColors.danger,
      surface: Colors.white,
      background: AppColors.lightMint,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary, // #4E1F6E Deep Purple Header
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      actionsIconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.lightMint, // #98E8DE
      selectedItemColor: AppColors.primary, // #4E1F6E Deep Purple
      unselectedItemColor: AppColors.secondary, // #3E3E75 Dark Indigo
      elevation: 8,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary, // #4E1F6E Deep Purple Primary Button
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.secondary, // #3E3E75 Dark Indigo Secondary Button
        side: const BorderSide(color: AppColors.secondary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );

  static ThemeData darkTheme = lightTheme;
}

