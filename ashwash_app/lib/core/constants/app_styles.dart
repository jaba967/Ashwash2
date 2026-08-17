import 'package:flutter/material.dart';

class AppStyles {
  // Border Radius Tokens
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusPill = 30.0;

  static final BorderRadius cardBorderRadius = BorderRadius.circular(radiusMedium);
  static final BorderRadius buttonBorderRadius = BorderRadius.circular(radiusPill);
  static final BorderRadius inputBorderRadius = BorderRadius.circular(radiusMedium);

  // Box Shadows (Matching Figma elevation)
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0F000000), // 6% black blur
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: Color(0x337C3AED), // 20% purple glow
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  // Spacing Tokens
  static const double spaceXS = 4.0;
  static const double spaceS = 8.0;
  static const double spaceM = 16.0;
  static const double spaceL = 24.0;
  static const double spaceXL = 32.0;
}
