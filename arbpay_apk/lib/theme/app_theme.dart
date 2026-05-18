import 'package:flutter/material.dart';

class AppTheme {
  final bool isDark;
  const AppTheme(this.isDark);

  // Backgrounds
  Color get bg      => isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF2F2F7);
  Color get surface => isDark ? const Color(0xFF13131A) : const Color(0xFFFFFFFF);
  Color get card    => isDark ? const Color(0xFF1C1C26) : const Color(0xFFFFFFFF);
  Color get border  => isDark ? const Color(0xFF2A2A38) : const Color(0xFFE0E0E8);

  // Text
  Color get textPrimary => isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0A0A0F);
  Color get textSub     => isDark ? const Color(0xFF8888A0) : const Color(0xFF6B6B80);
  Color get textDim     => isDark ? const Color(0xFF3A3A50) : const Color(0xFFBBBBCC);

  // Accent — always yellow
  Color get yellow    => const Color(0xFFFFCC00);
  Color get yellowDim => isDark ? const Color(0x33FFCC00) : const Color(0xFFFFCC00);

  // Status colors — same in both themes
  Color get red   => const Color(0xFFFF4444);
  Color get green => const Color(0xFF00C853);

  // System overlay style
  Brightness get overlayBrightness => isDark ? Brightness.light : Brightness.dark;

  // Log colors
  Color get logSuccess => isDark ? const Color(0xFF00E676) : const Color(0xFF00A844);
  Color get logWarning => isDark ? const Color(0xFFFFA726) : const Color(0xFFE65100);
  Color get logError   => isDark ? const Color(0xFFFF4444) : const Color(0xFFD32F2F);
  Color get logInfo    => isDark ? const Color(0xFF8888A0) : const Color(0xFF555566);
}
