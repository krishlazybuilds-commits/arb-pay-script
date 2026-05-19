import 'package:flutter/services.dart';

class IconService {
  static const _channel = MethodChannel('com.arbpay.bot/icon');

  /// Call this whenever the theme changes.
  /// [isDark] = true → dark launcher icon, false → light launcher icon.
  static Future<void> setIcon({required bool isDark}) async {
    try {
      await _channel.invokeMethod('setIcon', {'isDark': isDark});
    } on PlatformException catch (_) {
      // Silently ignore — older Android versions may not support this
    }
  }
}
