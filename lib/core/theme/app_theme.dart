import 'package:flutter/material.dart';

class AppTheme {
  // Core Palette
  static const Color background = Color(0xFFFFFFFF);
  static const Color accent = Color(0xFF111111);
  static const Color border = Color(0x12000000);
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color successAccent = Color(0xFF00E676);
  static const Color warningAccent = Color(0xFFFF9100);
  static const Color errorAccent = Color(0xFFFF1744);
  static const Color cardBackground = Color(0xFFF8F8F7);

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      primaryColor: accent,
      colorScheme: const ColorScheme.light(
        primary: accent,
        secondary: accent,
        surface: cardBackground,
        error: errorAccent,
        onPrimary: background,
        onSecondary: background,
        onSurface: textPrimary,
      ),
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 32),
        displayMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 28),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _CalmPageTransitionsBuilder(),
          TargetPlatform.iOS: _CalmPageTransitionsBuilder(),
          TargetPlatform.macOS: _CalmPageTransitionsBuilder(),
          TargetPlatform.linux: _CalmPageTransitionsBuilder(),
          TargetPlatform.windows: _CalmPageTransitionsBuilder(),
        },
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: background,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: border),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _CalmPageTransitionsBuilder extends PageTransitionsBuilder {
  const _CalmPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
        ),
        child: child,
      ),
    );
  }
}
