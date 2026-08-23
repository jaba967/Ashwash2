import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryPurple = Color(0xFFB388FF);
  static const Color deepPurple = Color(0xFF7C4DFF);
  static const Color lavenderBlue = Color(0xFFA18FFF);
  static const Color mintGreen = Color(0xFFB7F1E3);

  static const Color primary = primaryPurple; 
  static const Color secondary = lavenderBlue; 
  static const Color danger = Color(0xFFEF4444);
  static const Color success = mintGreen;
  static const Color warning = Color(0xFFF97316);

  static const Color glassSurface = Color(0x26FFFFFF); 
  static const Color glassBorder = Color(0x40FFFFFF); 
  
  static const Color bgLight = Colors.transparent; 
  static const Color bgDark = Colors.transparent; 
  static const Color cardLight = glassSurface;
  static const Color cardDark = glassSurface;

  static const Color darkBackground = bgDark;
  static const Color darkSurface = cardDark;

  static const Color textPrimaryLight = Colors.black;
  static const Color textSecondaryLight = Colors.white;
  static const Color textPrimaryDark = Colors.black; 
  static const Color textSecondaryDark = Colors.white;

  static const Color categoryPink = deepPurple;
  static const Color categoryPurple = primaryPurple;
  static const Color categoryBlue = lavenderBlue;
  static const Color categoryOrange = mintGreen;
  static const Color categoryTeal = mintGreen;

  static const Color categoryMother = categoryPink;
  static const Color categorySingleParent = categoryPurple;
  static const Color categorySpecialChild = categoryBlue;
  static const Color categoryCorporate = categoryOrange;
  static const Color categoryStudent = categoryTeal;

  static const Color surfaceLight = glassSurface;
  static const Color surfaceDark = glassSurface; 
  static const Color emergency = Color(0xFFEF4444);
  static const Color inputBgLight = deepPurple;
}
