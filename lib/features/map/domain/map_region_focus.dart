import 'package:flutter/material.dart';
import 'map_region.dart';

class MapFocus {
  final Offset focalPoint; // normalized (0..1)
  final double scale;

  const MapFocus(this.focalPoint, this.scale);
}

const mapRegionFocus = <MapRegion, MapFocus>{
  MapRegion.world: MapFocus(Offset(0.5, 0.5), 1.0),
  MapRegion.africa: MapFocus(Offset(0.52, 0.52), 5.0),
  MapRegion.europe: MapFocus(Offset(0.50, 0.35), 3.0),
  MapRegion.northAmerica: MapFocus(Offset(0.25, 0.30), 2.5),
  MapRegion.southAmerica: MapFocus(Offset(0.35, 0.65), 2.5),
  MapRegion.asia: MapFocus(Offset(0.75, 0.35), 2.5),
};
