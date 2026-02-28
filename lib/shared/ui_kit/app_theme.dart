import 'package:flutter/material.dart';
import 'app_style.dart';

class AppTheme {
  static ThemeData light({required Color seed}) => _base(Brightness.light, seed);
  static ThemeData dark({required Color seed}) => _base(Brightness.dark, seed);

  static ThemeData _base(Brightness brightness, Color seed) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      extensions: const <ThemeExtension<dynamic>>[
        AppStyle(
          backgroundBlobOpacity: 0.08, // 👈 global knob
        ),
      ],
    );
  }
}