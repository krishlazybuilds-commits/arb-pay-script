import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  final bool isDark;
  const AppTheme(this.isDark);

  // ── Backgrounds ────────────────────────────────────────────────────────────
  Color get bg      => isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF2F2F7);
  Color get surface => isDark ? const Color(0xFF13131A) : const Color(0xFFFFFFFF);
  Color get card    => isDark ? const Color(0xFF1C1C26) : const Color(0xFFFFFFFF);
  Color get border  => isDark ? const Color(0xFF2A2A38) : const Color(0xFFE0E0E8);

  // ── Text ───────────────────────────────────────────────────────────────────
  Color get textPrimary => isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0A0A0F);
  Color get textSub     => isDark ? const Color(0xFF8888A0) : const Color(0xFF6B6B80);
  Color get textDim     => isDark ? const Color(0xFF3A3A50) : const Color(0xFFBBBBCC);

  // ── Accent ─────────────────────────────────────────────────────────────────
  Color get yellow    => const Color(0xFFFFCC00);
  Color get yellowDim => isDark ? const Color(0x33FFCC00) : const Color(0x1AFFCC00);

  // ── Status ─────────────────────────────────────────────────────────────────
  Color get red   => const Color(0xFFFF4444);
  Color get green => const Color(0xFF00C853);

  // ── Log colors ─────────────────────────────────────────────────────────────
  Color get logSuccess => isDark ? const Color(0xFF00E676) : const Color(0xFF00A844);
  Color get logWarning => isDark ? const Color(0xFFFFA726) : const Color(0xFFE65100);
  Color get logError   => isDark ? const Color(0xFFFF4444) : const Color(0xFFD32F2F);
  Color get logInfo    => isDark ? const Color(0xFF8888A0) : const Color(0xFF555566);

  // ── System overlay ─────────────────────────────────────────────────────────
  Brightness get overlayBrightness => isDark ? Brightness.light : Brightness.dark;

  // ── Build a full ThemeData from this AppTheme ──────────────────────────────
  // Single source of truth — main.dart calls this instead of defining its own.
  ThemeData toThemeData() {
    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: yellow,
        onPrimary: bg,
        secondary: yellow,
        onSecondary: bg,
        surface: surface,
        onSurface: textPrimary,
        error: red,
        onError: const Color(0xFFFFFFFF),
        // extras used by widgets that read Theme.of(context)
        outline: border,
        surfaceContainerHighest: card,
      ),
      fontFamily: 'sans-serif',
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: border),
        ),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 0.5),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        labelStyle: TextStyle(color: textSub, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: yellow, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: yellow,
        contentTextStyle: TextStyle(color: bg, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
      iconTheme: IconThemeData(color: textSub),
      textTheme: TextTheme(
        bodyLarge:  TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textPrimary),
        bodySmall:  TextStyle(color: textSub),
      ),
    );
  }

  // ── Convenience: read AppTheme from BuildContext via Theme ─────────────────
  // Usage: final t = AppTheme.of(context);
  static AppTheme of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppTheme(isDark);
  }
}
