import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const Color _seed = Color(0xFF5565FF);

  static ThemeData light() => _theme(Brightness.light, const Color(0xFFF8F9FB));

  static ThemeData dark() => _theme(Brightness.dark, const Color(0xFF101114));

  static ThemeData _theme(Brightness brightness, Color background) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: scheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}
