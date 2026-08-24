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

  static ThemeData darkTheme = lightTheme;
}


