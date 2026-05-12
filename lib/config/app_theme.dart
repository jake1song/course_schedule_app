import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ── Colors ──

  static const Color primaryStart = Color(0xFF0066FF);
  static const Color primaryEnd = Color(0xFF7C3AED);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryStart, primaryEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color surfaceLight = Color(0xB8FFFFFF); // rgba(255,255,255,0.72)
  static const Color surfaceBorder = Color(0x66FFFFFF); // rgba(255,255,255,0.4)
  static const Color background = Color(0xFFF2F4F7);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color cardBorder = Color(0x1A000000); // subtle border

  static const Color filledInputBg = Color(0xFFF1F3F7);

  // ── Shadows ──

  static const BoxShadow cardShadow = BoxShadow(
    color: Color(0x0F000000),
    blurRadius: 16,
    offset: Offset(0, 4),
  );

  static const BoxShadow floatingNavShadow = BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 24,
    offset: Offset(0, -2),
  );

  // ── Radii ──

  static const double cardRadius = 20;
  static const double smallRadius = 14;
  static const double pillRadius = 28;
  static const double inputRadius = 14;

  static const BorderRadius cardBorderRadius = BorderRadius.all(Radius.circular(cardRadius));
  static const BorderRadius smallBorderRadius = BorderRadius.all(Radius.circular(smallRadius));
  static const BorderRadius pillBorderRadius = BorderRadius.all(Radius.circular(pillRadius));
  static const BorderRadius inputBorderRadius = BorderRadius.all(Radius.circular(inputRadius));

  static const BorderRadius topSheetRadius = BorderRadius.vertical(top: Radius.circular(32));

  // ── Bubble radii (chat) ──

  static const BorderRadius userBubbleRadius = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
    bottomLeft: Radius.circular(20),
    bottomRight: Radius.circular(4),
  );

  static const BorderRadius aiBubbleRadius = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
    bottomLeft: Radius.circular(4),
    bottomRight: Radius.circular(20),
  );

  // ── Period accent colors ──

  static const Map<String, Color> periodColors = {
    '第1节': Color(0xFF0066FF), // blue
    '第2节': Color(0xFF10B981), // green
    '第3节': Color(0xFFF59E0B), // orange
    '第4节': Color(0xFF8B5CF6), // purple
    '第5节': Color(0xFFF97316), // sunset
    '第6节': Color(0xFF1E3A5F), // navy
  };

  static Color periodColor(String period) =>
      periodColors[period] ?? textSecondary;

  // ── Spacing ──

  static const double cardGap = 20;
  static const double cardHPadding = 20;
  static const double cardVPadding = 16;
  static const double screenHPadding = 20;
  static const double sectionGap = 24;

  // ── Typography ──

  static const TextStyle heroTitle = TextStyle(
    fontSize: 28, fontWeight: FontWeight.w300, color: Colors.white, height: 1.15,
  );

  static const TextStyle pageTitle = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w400, color: textPrimary,
  );

  static const TextStyle captionText = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w400, color: textSecondary,
  );

  static const TextStyle tinyText = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400, color: textTertiary,
  );

  // ── Card decoration helpers ──

  static BoxDecoration glassCard({Color? bg}) => BoxDecoration(
    color: bg ?? surfaceLight,
    borderRadius: cardBorderRadius,
    border: Border.all(color: cardBorder, width: 0.5),
    boxShadow: const [cardShadow],
  );

  static BoxDecoration gradientCard() => BoxDecoration(
    gradient: primaryGradient,
    borderRadius: cardBorderRadius,
    boxShadow: const [cardShadow],
  );

  // ── Input decoration theme ──

  static InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: filledInputBg,
    border: OutlineInputBorder(
      borderRadius: inputBorderRadius,
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: inputBorderRadius,
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: inputBorderRadius,
      borderSide: const BorderSide(color: primaryStart, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}
