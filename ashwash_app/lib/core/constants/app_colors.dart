import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFA855F7); // Purple from Web
  static const Color secondary = Color(0xFF6366F1); // Indigo from Web
  static const Color danger = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF97316);

  static const Color bgLight = Color(0xFFF8FAFC); // Slate 50
  static const Color bgDark = Color(0xFF0F172A); // Slate 900
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1E293B); // Slate 800

  static const Color darkBackground = bgDark;
  static const Color darkSurface = cardDark;

  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);

  // Category Theme Colors from Figma
  static const Color categoryPink = Color(0xFFEC4899);
  static const Color categoryPurple = Color(0xFF8B5CF6);
  static const Color categoryBlue = Color(0xFF3B82F6);
  static const Color categoryOrange = Color(0xFFF97316);
  static const Color categoryTeal = Color(0xFF14B8A6);

  // Category Aliases
  static const Color categoryMother = categoryPink;
  static const Color categorySingleParent = categoryPurple;
  static const Color categorySpecialChild = categoryBlue;
  static const Color categoryCorporate = categoryOrange;
  static const Color categoryStudent = categoryTeal;

  // Surface & Input Colors
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1F2937);
  static const Color emergency = Color(0xFFDC2626);
  static const Color inputBgLight = Color(0xFFF3F4F6);
}
