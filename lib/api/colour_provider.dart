import 'package:flutter/material.dart';

class Colours extends ThemeExtension<Colours> {
  const Colours({required this.darkMode});

  // system = null
  // dark   = true
  // light  = false
  final bool darkMode;

  // Brand Foreground / Text Palette (from globals.css)
  Color get primaryLight => darkMode ? const Color(0xFFEAEFEF) : const Color(0xFF1E293B);
  Color get secondaryLight => darkMode ? const Color(0xFFBFC9D1) : const Color(0xFF64748B);
  Color get tertiaryLight => darkMode ? const Color(0xFF8FA0AE) : const Color(0xFF94A3B8);

  // Brand Background / Surface Palette (from globals.css)
  Color get primaryDark => darkMode ? const Color(0xFF16212B) : const Color(0xFFFFFFFF);
  Color get secondaryDark => darkMode ? const Color(0xFF1E2B38) : const Color(0xFFF1F5F9);
  Color get tertiaryDark => darkMode ? const Color(0xFF253545) : const Color(0xFFE2E8F0);

  // Brand Primary Accent (#FF9B51 / #F97316) & Positive Semantic
  Color get accent => darkMode ? const Color(0xFFFF9B51) : const Color(0xFFF97316);
  Color get primaryPositive => darkMode ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
  Color get secondaryPositive => darkMode ? const Color(0xFF1E3A2F) : const Color(0xFFDCFCE7);
  Color get tertiaryPositive => darkMode ? const Color(0xFFFF9B51) : const Color(0xFFF97316);

  // Destructive / Negative Semantic (#EF4444)
  Color get primaryNegative => darkMode ? const Color(0xFFEF4444) : const Color(0xFFDC2626);
  Color get secondaryNegative => darkMode ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2);
  Color get tertiaryNegative => darkMode ? const Color(0xFFF87171) : const Color(0xFFB91C1C);

  // Warning Semantic (#F59E0B)
  Color get primaryWarning => darkMode ? const Color(0xFFF59E0B) : const Color(0xFFD97706);
  Color get secondaryWarning => darkMode ? const Color(0xFF78350F) : const Color(0xFFFEF3C7);
  Color get tertiaryWarning => darkMode ? const Color(0xFFFBBF24) : const Color(0xFFB45309);

  // Info Semantic (#3B82F6)
  Color get primaryInfo => darkMode ? const Color(0xFF3B82F6) : const Color(0xFF2563EB);
  Color get secondaryInfo => darkMode ? const Color(0xFF1E3A5F) : const Color(0xFFDBEAFE);
  Color get tertiaryInfo => darkMode ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8);

  // Premium page palette (mapped to brand slate + orange)
  Color get premiumBg => darkMode ? const Color(0xFF16212B) : const Color(0xFFF8FAFC);
  Color get premiumSurface => darkMode ? const Color(0xFF1E2B38) : const Color(0xFFF1F5F9);
  Color get premiumBorder => darkMode ? const Color(0xFF253545) : const Color(0xFFE2E8F0);
  Color get premiumAccent => darkMode ? const Color(0xFFFF9B51) : const Color(0xFFF97316);
  Color get premiumTextSecondary => darkMode ? const Color(0xFFBFC9D1) : const Color(0xFF64748B);

  // Showcase palette (mapped to brand slate + orange)
  Color get showcaseBg => darkMode ? const Color(0xFF1E2B38) : const Color(0xFFF1F5F9);
  Color get showcaseTitle => darkMode ? const Color(0xFFEAEFEF) : const Color(0xFF1E293B);
  Color get showcaseDesc => darkMode ? const Color(0xFFBFC9D1) : const Color(0xFF64748B);
  Color get showcaseBtnPrimary => darkMode ? const Color(0xFFFF9B51) : const Color(0xFFF97316);
  Color get showcaseBtnSecondary => darkMode ? const Color(0xFF253545) : const Color(0xFFE2E8F0);
  Color get showcaseBtnText => darkMode ? const Color(0xFF16212B) : const Color(0xFFFFFFFF);
  Color get showcaseBorder => darkMode ? const Color(0xFF253545) : const Color(0xFFCBD5E1);
  Color get showcaseFeatureIcon => darkMode ? const Color(0xFFFF9B51) : const Color(0xFFF97316);

  Color get gitlabOrange => const Color(0xFFFC6D26);
  Color get giteaGreen => const Color(0xFF609926);
  Color get codebergBlue => const Color(0xFF2185D0);

  @override
  Colours copyWith({bool? darkMode}) => Colours(darkMode: darkMode ?? this.darkMode);

  @override
  Colours lerp(covariant ThemeExtension<Colours>? other, double t) => other is Colours ? other : this;
}
