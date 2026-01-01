import 'package:flutter/material.dart';
import '../../domain/map_region.dart';
import '../../domain/map_region_focus.dart';

typedef FocusFn = bool Function(Offset focalPoint, double scale);

class MapCameraController {
  FocusFn? _focusFn;

  Offset? _pendingFocalPoint;
  double? _pendingScale;

  void attach({required FocusFn focusFn}) {
    _focusFn = focusFn;
    // DO NOT flush here (map may not be sized yet)
  }

  void flushPending() {
    if (_focusFn == null) return;
    if (_pendingFocalPoint == null || _pendingScale == null) return;

    final ok = _focusFn!.call(_pendingFocalPoint!, _pendingScale!);
    if (ok) {
      _pendingFocalPoint = null;
      _pendingScale = null;
    }
  }

  void focusOnNormalized(Offset focalPoint, {double scale = 2.5}) {
    _pendingFocalPoint = focalPoint;
    _pendingScale = scale;

    // Try immediately if possible; if not, it stays pending.
    flushPending();
  }

  void focusOnRegion(MapRegion region) {
    final focus = mapRegionFocus[region];
    if (focus == null) return;
    focusOnNormalized(focus.focalPoint, scale: focus.scale);
  }
}
