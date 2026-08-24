import 'package:flutter/material.dart';

class AppColors {
  // Strict 4-Color Palette
  static const Color primary = Color(0xFF4E1F6E); // Deep Purple
  static const Color secondary = Color(0xFF3E3E75); // Dark Indigo
  static const Color accent = Color(0xFF45A9A9); // Teal (CTA / Active element)
  static const Color mint = Color(0xFF98E8DE); // Light Mint (Page / Section / Card Background)

  static const Color deepPurple = Color(0xFF4E1F6E);
  static const Color darkIndigo = Color(0xFF3E3E75);
  static const Color teal = Color(0xFF45A9A9);
  static const Color lightMint = Color(0xFF98E8DE);

  // Status & Utility
  static const Color danger = Color(0xFFEF4444);
  static const Color success = Color(0xFF45A9A9);
  static const Color warning = Color(0xFF45A9A9);
  static const Color emergency = Color(0xFFEF4444);

  // Backgrounds & Surfaces (Rich 4-Color Theme: Light Mint #98E8DE background)
  static const Color bgLight = Color(0xFF98E8DE); // Light Mint
  static const Color bgDark = Color(0xFF98E8DE); // Light Mint
  static const Color cardLight = Color(0xFFFFFFFF); // Surface Card
  static const Color cardDark = Color(0xFFFFFFFF);

  static const Color darkBackground = bgLight;
  static const Color darkSurface = cardLight;

  // Text Colors (Dark Indigo #3E3E75 & Deep Purple #4E1F6E for crisp contrast on Light Mint)
  static const Color textPrimary = Color(0xFF3E3E75);
  static const Color textSecondary = Color(0xFF4E1F6E);
  static const Color textPrimaryLight = Color(0xFF3E3E75);
  static const Color textSecondaryLight = Color(0xFF4E1F6E);
  static const Color textPrimaryDark = Color(0xFF3E3E75);
  static const Color textSecondaryDark = Color(0xFF4E1F6E);

  // Category Colors mapped strictly to 4-color palette
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
  static const Color inputBgLight = Color(0xFF98E8DE);
  static const Color glassSurface = Color(0xFF98E8DE);
}

