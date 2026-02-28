import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_style.dart';

enum AppToastTone { normal, success, danger }

class AppToast {
  static void show(
      BuildContext context, {
        required String message,
        AppToastTone tone = AppToastTone.normal,
        Duration duration = const Duration(seconds: 3),
      }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.clearSnackBars();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final style = context.style;

    final Color accent = switch (tone) {
      AppToastTone.normal => cs.primary,
      AppToastTone.success => Colors.green,
      AppToastTone.danger => cs.error,
    };

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: duration,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        content: _ToastSurface(
          message: message,
          accent: accent,
          borderOpacity: style.cardBorderOpacity,
          blurSigma: style.cardBlurSigma,
          surfaceOpacity: style.cardSurfaceOpacity,
        ),
      ),
    );
  }
}

class _ToastSurface extends StatelessWidget {
  const _ToastSurface({
    required this.message,
    required this.accent,
    required this.borderOpacity,
    required this.blurSigma,
    required this.surfaceOpacity,
  });

  final String message;
  final Color accent;
  final double borderOpacity;
  final double blurSigma;
  final double surfaceOpacity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final style = context.style;

    final r = BorderRadius.circular(style.cardRadius);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: [
          BoxShadow(
            blurRadius: 26,
            offset: const Offset(0, 14),
            color: accent.withOpacity(theme.brightness == Brightness.dark ? .18 : .10),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: r,
          border: Border.all(color: cs.outlineVariant.withOpacity(borderOpacity)),
        ),
        child: ClipRRect(
          borderRadius: r,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: Container(
              color: cs.surface.withOpacity(surfaceOpacity),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}