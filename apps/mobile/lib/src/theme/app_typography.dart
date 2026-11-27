import 'package:flutter/material.dart';

/// Starting sizes are logical pixels; system TextScaler is never capped.
abstract final class AppTypography {
  static const gold = Color(0xFFF4D58D);
  static const ivory = Color(0xFFFFF4DF);
  static const background = Color(0xFF160B28);
  static const fallback = [
    'Noto Sans',
    'Noto Color Emoji',
    'Apple Color Emoji',
  ];
  static const heading = TextStyle(
    fontFamily: 'Cinzel',
    fontWeight: FontWeight.w700,
    fontSize: 28,
    color: gold,
    fontFamilyFallback: fallback,
  );
  static const button = TextStyle(
    fontFamily: 'Nunito',
    fontWeight: FontWeight.w800,
    fontSize: 16,
    color: ivory,
    fontFamilyFallback: fallback,
  );
  static const playerName = TextStyle(
    fontFamily: 'Nunito',
    fontWeight: FontWeight.w700,
    fontSize: 15,
    color: ivory,
    fontFamilyFallback: fallback,
  );
  static const status = TextStyle(
    fontFamily: 'Nunito',
    fontWeight: FontWeight.w600,
    fontSize: 15,
    color: ivory,
    fontFamilyFallback: fallback,
    height: 1.2,
  );
  static const body = TextStyle(
    fontFamily: 'Nunito',
    fontWeight: FontWeight.w400,
    fontSize: 15,
    color: ivory,
    fontFamilyFallback: fallback,
  );
  static TextTheme get textTheme => const TextTheme(
        displayLarge: heading,
        displayMedium: heading,
        displaySmall: heading,
        headlineLarge: heading,
        headlineMedium: heading,
        headlineSmall: heading,
        titleLarge: heading,
        titleMedium: playerName,
        titleSmall: status,
        bodyLarge: body,
        bodyMedium: body,
        bodySmall: body,
        labelLarge: button,
        labelMedium: status,
        labelSmall: body,
      );
}
