import 'package:flutter/material.dart';

class MapFocus {
  final Offset focalPoint; // normalized (0..1)
  final double scale;

  const MapFocus({
    required this.focalPoint,
    required this.scale,
  });
}
