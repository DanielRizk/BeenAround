import 'dart:ui';

import 'package:flutter/material.dart';

@immutable
class AppStyle extends ThemeExtension<AppStyle> {
  const AppStyle({
    this.cardRadius = 24,
    this.iconRadius = 16,
    this.cardBlurSigma = 12,
    this.backgroundBlobOpacity = 0.08, // 👈 your “one var”
    this.cardBorderOpacity = 0.35,
    this.cardSurfaceOpacity = 0.72,
    this.pressScale = 0.992,
    this.entranceMs = 650,
    this.bgLoopSeconds = 10,
  });

  final double cardRadius;
  final double iconRadius;
  final double cardBlurSigma;
  final double backgroundBlobOpacity;
  final double cardBorderOpacity;
  final double cardSurfaceOpacity;
  final double pressScale;
  final int entranceMs;
  final int bgLoopSeconds;

  @override
  AppStyle copyWith({
    double? cardRadius,
    double? iconRadius,
    double? cardBlurSigma,
    double? backgroundBlobOpacity,
    double? cardBorderOpacity,
    double? cardSurfaceOpacity,
    double? pressScale,
    int? entranceMs,
    int? bgLoopSeconds,
  }) {
    return AppStyle(
      cardRadius: cardRadius ?? this.cardRadius,
      iconRadius: iconRadius ?? this.iconRadius,
      cardBlurSigma: cardBlurSigma ?? this.cardBlurSigma,
      backgroundBlobOpacity: backgroundBlobOpacity ?? this.backgroundBlobOpacity,
      cardBorderOpacity: cardBorderOpacity ?? this.cardBorderOpacity,
      cardSurfaceOpacity: cardSurfaceOpacity ?? this.cardSurfaceOpacity,
      pressScale: pressScale ?? this.pressScale,
      entranceMs: entranceMs ?? this.entranceMs,
      bgLoopSeconds: bgLoopSeconds ?? this.bgLoopSeconds,
    );
  }

  @override
  AppStyle lerp(ThemeExtension<AppStyle>? other, double t) {
    if (other is! AppStyle) return this;
    return AppStyle(
      cardRadius: lerpDouble(cardRadius, other.cardRadius, t)!,
      iconRadius: lerpDouble(iconRadius, other.iconRadius, t)!,
      cardBlurSigma: lerpDouble(cardBlurSigma, other.cardBlurSigma, t)!,
      backgroundBlobOpacity: lerpDouble(backgroundBlobOpacity, other.backgroundBlobOpacity, t)!,
      cardBorderOpacity: lerpDouble(cardBorderOpacity, other.cardBorderOpacity, t)!,
      cardSurfaceOpacity: lerpDouble(cardSurfaceOpacity, other.cardSurfaceOpacity, t)!,
      pressScale: lerpDouble(pressScale, other.pressScale, t)!,
      entranceMs: (entranceMs + ((other.entranceMs - entranceMs) * t)).round(),
      bgLoopSeconds: (bgLoopSeconds + ((other.bgLoopSeconds - bgLoopSeconds) * t)).round(),
    );
  }
}

extension AppStyleX on BuildContext {
  AppStyle get style => Theme.of(this).extension<AppStyle>() ?? const AppStyle();
}