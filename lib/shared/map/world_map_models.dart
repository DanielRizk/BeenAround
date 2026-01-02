import 'dart:ui';

import 'package:flutter/foundation.dart';

@immutable
class WorldMapData {
  final Size canvasSize;
  final List<CountryShape> countries;
  final Map<String, String> nameById;
  final Rect viewBox;

  // ✅ new: precomputed label anchors
  final Map<String, Offset> labelAnchorById;

  const WorldMapData({
    required this.canvasSize,
    required this.countries,
    required this.nameById,
    required this.viewBox,
    required this.labelAnchorById,
  });

  WorldMapData copyWith({
    Size? canvasSize,
    List<CountryShape>? countries,
    Map<String, String>? nameById,
    Rect? viewBox,
    Map<String, Offset>? labelAnchorById,
  }) {
    return WorldMapData(
      canvasSize: canvasSize ?? this.canvasSize,
      countries: countries ?? this.countries,
      nameById: nameById ?? this.nameById,
      viewBox: viewBox ?? this.viewBox,
      labelAnchorById: labelAnchorById ?? this.labelAnchorById,
    );
  }
}


@immutable
class CountryShape {
  final String id;
  final String name;
  final Path path;
  final Rect bounds;

  const CountryShape({
    required this.id,
    required this.name,
    required this.path,
    required this.bounds,
  });

  CountryShape copyWith({
    String? id,
    String? name,
    Path? path,
    Rect? bounds,
  }) {
    return CountryShape(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      bounds: bounds ?? this.bounds,
    );
  }
}

