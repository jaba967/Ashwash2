import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static TextStyle heading1(BuildContext context, {Color? color}) {
    return GoogleFonts.outfit(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
    );
  }

  static TextStyle heading2(BuildContext context, {Color? color}) {
    return GoogleFonts.outfit(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
    );
  }

  static TextStyle heading3(BuildContext context, {Color? color}) {
    return GoogleFonts.outfit(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
    );
  }

  static TextStyle body(BuildContext context, {Color? color, double fontSize = 14, FontWeight fontWeight = FontWeight.normal}) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? Theme.of(context).textTheme.bodyMedium?.color,
    );
  }

  static TextStyle bangla(BuildContext context, {Color? color, double fontSize = 14, FontWeight fontWeight = FontWeight.normal}) {
    return GoogleFonts.hindSiliguri(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? Theme.of(context).textTheme.bodyMedium?.color,
    );
  }
}
