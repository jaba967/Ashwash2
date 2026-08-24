import 'package:flutter/material.dart';

class AppColors {
  // 4-Color Palette requested by User
  static const Color primary = Color(0xFF4E1F6E); // Deep Purple
  static const Color secondary = Color(0xFF3E3E75); // Dark Indigo
  static const Color accent = Color(0xFF45A9A9); // Teal (CTA / Active element)
  static const Color mint = Color(0xFF98E8DE); // Light Mint (Card / Highlight area)

  static const Color deepPurple = Color(0xFF4E1F6E);
  static const Color darkIndigo = Color(0xFF3E3E75);
  static const Color teal = Color(0xFF45A9A9);
  static const Color lightMint = Color(0xFF98E8DE);

  // Status & Utility
  static const Color danger = Color(0xFFEF4444);
  static const Color success = Color(0xFF45A9A9);
  static const Color warning = Color(0xFFF97316);
  static const Color emergency = Color(0xFFEF4444);

  // Backgrounds & Surfaces (Clean white / light gray backgrounds)
  static const Color bgLight = Color(0xFFFFFFFF);
  static const Color bgDark = Color(0xFFF8F9FA);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFFFFFFFF);

  static const Color darkBackground = bgLight;
  static const Color darkSurface = cardLight;

  // Text Colors
  static const Color textPrimary = Color(0xFF1F1F1F);
  static const Color textSecondary = Color(0xFF3E3E75);
  static const Color textPrimaryLight = Color(0xFF1F1F1F);
  static const Color textSecondaryLight = Color(0xFF3E3E75);
  static const Color textPrimaryDark = Color(0xFF1F1F1F);
  static const Color textSecondaryDark = Color(0xFF3E3E75);

  // Category Colors mapped to palette accents
  static const Color categoryPink = Color(0xFF4E1F6E);
  static const Color categoryPurple = Color(0xFF3E3E75);
  static const Color categoryBlue = Color(0xFF45A9A9);
  static const Color categoryOrange = Color(0xFF45A9A9);
  static const Color categoryTeal = Color(0xFF45A9A9);

  // Category Aliases
  static const Color categoryMother = categoryPink;
  static const Color categorySingleParent = categoryPurple;
  static const Color categorySpecialChild = categoryBlue;
  static const Color categoryCorporate = categoryOrange;
  static const Color categoryStudent = categoryTeal;

  // Surface & Input Colors
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFFFFFFFF);
  static const Color inputBgLight = Color(0xFFF8F9FA);
}
