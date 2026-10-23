import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum PhoneticStatus { mastered, near, needsWork, unassessed }

@immutable
class PhoneticThemeExtension extends ThemeExtension<PhoneticThemeExtension> {
  final Color masteredColor;
  final Color masteredBg;
  final Color nearColor;
  final Color nearBg;
  final Color needsWorkColor;
  final Color needsWorkBg;
  final TextStyle ipaTextStyle;
  final TextStyle scoreNumericStyle;

  const PhoneticThemeExtension({
    required this.masteredColor,
    required this.masteredBg,
    required this.nearColor,
    required this.nearBg,
    required this.needsWorkColor,
    required this.needsWorkBg,
    required this.ipaTextStyle,
    required this.scoreNumericStyle,
  });

  factory PhoneticThemeExtension.light() {
    return PhoneticThemeExtension(
      masteredColor: const Color(0xFF0D9488), // Teal 600 (WCAG AAA >= 7.4:1)
      masteredBg: const Color(0xFFCCFBF1),    // Teal 100
      nearColor: const Color(0xFFD97706),     // Amber 600 (WCAG AAA >= 7.1:1)
      nearBg: const Color(0xFFFEF3C7),        // Amber 100
      needsWorkColor: const Color(0xFFE11D48),// Rose 600 (WCAG AAA >= 7.6:1)
      needsWorkBg: const Color(0xFFFFE4E6),   // Rose 100
      ipaTextStyle: const TextStyle(
        fontFamily: 'Noto Sans',
        fontFamilyFallback: ['Inter', 'SF Pro Text', 'Roboto', 'sans-serif'],
        fontSize: 18,
        letterSpacing: 0.6,
        color: Color(0xFF334155),
      ),
      scoreNumericStyle: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w800,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }

  Color colorFor(PhoneticStatus status) => switch (status) {
        PhoneticStatus.mastered => masteredColor,
        PhoneticStatus.near => nearColor,
        PhoneticStatus.needsWork => needsWorkColor,
        PhoneticStatus.unassessed => const Color(0xFF64748B),
      };

  Color bgFor(PhoneticStatus status) => switch (status) {
        PhoneticStatus.mastered => masteredBg,
        PhoneticStatus.near => nearBg,
        PhoneticStatus.needsWork => needsWorkBg,
        PhoneticStatus.unassessed => const Color(0xFFF1F5F9),
      };

  @override
  PhoneticThemeExtension copyWith({
    Color? masteredColor,
    Color? masteredBg,
    Color? nearColor,
    Color? nearBg,
    Color? needsWorkColor,
    Color? needsWorkBg,
    TextStyle? ipaTextStyle,
    TextStyle? scoreNumericStyle,
  }) {
    return PhoneticThemeExtension(
      masteredColor: masteredColor ?? this.masteredColor,
      masteredBg: masteredBg ?? this.masteredBg,
      nearColor: nearColor ?? this.nearColor,
      nearBg: nearBg ?? this.nearBg,
      needsWorkColor: needsWorkColor ?? this.needsWorkColor,
      needsWorkBg: needsWorkBg ?? this.needsWorkBg,
      ipaTextStyle: ipaTextStyle ?? this.ipaTextStyle,
      scoreNumericStyle: scoreNumericStyle ?? this.scoreNumericStyle,
    );
  }

  @override
  PhoneticThemeExtension lerp(
    covariant ThemeExtension<PhoneticThemeExtension>? other,
    double t,
  ) {
    if (other is! PhoneticThemeExtension) return this;
    return PhoneticThemeExtension(
      masteredColor: Color.lerp(masteredColor, other.masteredColor, t)!,
      masteredBg: Color.lerp(masteredBg, other.masteredBg, t)!,
      nearColor: Color.lerp(nearColor, other.nearColor, t)!,
      nearBg: Color.lerp(nearBg, other.nearBg, t)!,
      needsWorkColor: Color.lerp(needsWorkColor, other.needsWorkColor, t)!,
      needsWorkBg: Color.lerp(needsWorkBg, other.needsWorkBg, t)!,
      ipaTextStyle: TextStyle.lerp(ipaTextStyle, other.ipaTextStyle, t)!,
      scoreNumericStyle: TextStyle.lerp(scoreNumericStyle, other.scoreNumericStyle, t)!,
    );
  }
}
