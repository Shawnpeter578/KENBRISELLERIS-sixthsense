import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ---------------------------------------------------------------------
/// DESIGN TOKENS — Blue & White
/// A clean, trustworthy "clinical-calm" palette: deep marine blue for
/// headings and hero surfaces, a vivid sky blue as the single accent,
/// and soft blue-tinted whites everywhere else. Red is kept ONLY for
/// genuine low-battery / alert states — everything else stays on-palette.
/// ---------------------------------------------------------------------
class AppColors {
  // Core surfaces
  static const bg = Color(0xFFF3F7FD); // page background, faint blue-white
  static const surface = Color(0xFFFFFFFF); // card surface
  static const surfaceTint = Color(0xFFEAF2FE); // icon chips, sunken areas

  // Text
  static const ink = Color(0xFF0B2545); // deep marine — headings
  static const steel = Color(0xFF3E6293); // secondary text / icons
  static const muted = Color(0xFF8CA2C2); // captions, timestamps
  static const hairline = Color(0xFFDCE7F7);

  // Brand blues
  static const heroTop = Color(0xFF1B4B91);
  static const heroMid = Color(0xFF2F6FED);
  static const heroBottom = Color(0xFF5B9DF7);
  static const accent = Color(0xFF2F6FED); // primary accent — buttons, rings
  static const accentDeep = Color(0xFF1B4B91);
  static const accentTint = Color(0xFFDCE9FE);
  static const accentSoft = Color(0xFFEFF5FF);

  // Status (kept minimal — used only where meaning truly differs from "on brand")
  static const success = Color(0xFF2F8F6E); // muted teal-green, reads as "on-palette ok"
  static const successTint = Color(0xFFE3F3EC);
  static const warning = Color(0xFFCE8A1E);
  static const warningTint = Color(0xFFFBF0DC);
  static const danger = Color(0xFFD6534A); // reserved for real low-battery alerts
  static const dangerTint = Color(0xFFFBE6E4);

  static const cardShadow = Color(0x1F2F6FED); // soft blue-tinted shadow
}

class AppText {
  static TextStyle display = GoogleFonts.manrope(
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
    letterSpacing: -0.4,
  );

  static TextStyle body = GoogleFonts.manrope(
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
  );

  // Numeric / device readouts — battery %, distances, timestamps.
  static TextStyle mono = GoogleFonts.jetBrainsMono(
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );
}

ThemeData buildAppTheme() {
  return ThemeData(
    scaffoldBackgroundColor: AppColors.bg,
    fontFamily: GoogleFonts.manrope().fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
  );
}