import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../shared/map/world_map_models.dart';
import '../../../shared/settings/app_settings.dart';
import '../presentation/utils/map_transform_clamper.dart';
import '../presentation/widgets/world_map_labels_painter.dart';
import 'world_map_painter.dart';

class WorldMapView extends StatefulWidget {
  final WorldMapData map;
  final ValueNotifier<Set<String>> selectedIds;

  /// Called when the user taps a country shape (visited filtering is done by the caller).
  final ValueChanged<String>? onCountryTap;

  const WorldMapView({
    super.key,
    required this.map,
    required this.selectedIds,
    this.onCountryTap,
  });

  @override
  State<WorldMapView> createState() => WorldMapViewState();
}

class WorldMapViewState extends State<WorldMapView>
    with SingleTickerProviderStateMixin {
  final TransformationController _tc = TransformationController();

  bool _initialized = false;
  bool _isClamping = false;

  Size _viewport = Size.zero;
  double _fitWidthScale = 1.0;

  AnimationController? _anim;
  Animation<Matrix4>? _matrixAnim;

  @override
  void initState() {
    super.initState();
    _tc.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _tc.removeListener(_onTransformChanged);
    _tc.dispose();
    _anim?.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    if (_isClamping) return;
    if (_viewport == Size.zero) return;

    _isClamping = true;
    try {
      final clamped = MapTransformClamper.clampToViewport(
        transform: _tc.value,
        viewportSize: _viewport,
        contentSize: widget.map.canvasSize,
      );

      if (!_matrixAlmostEqual(_tc.value, clamped)) {
        _tc.value = clamped;
      }
    } finally {
      _isClamping = false;
    }
  }

  // ==========================
  // Public API (used by MapPage)
  // ==========================

  void focusCountry(String iso2) {
    if (_viewport == Size.zero) return;

    final c = widget.map.countries.cast<CountryShape?>().firstWhere(
          (x) => x!.id == iso2,
          orElse: () => null,
        );
    if (c == null) return;

    final target = _matrixForRect(c.bounds.inflate(18.0));

    _animateTo(target);
  }

  // ==========================
  // Zoom helpers
  // ==========================

  Matrix4 _matrixForRect(Rect rect) {
    // Fit the rect into the viewport, keep a bit of margin.
    final minScale = _fitWidthScale;
    final maxScale = _fitWidthScale * 100.0;

    final sx = _viewport.width / rect.width;
    final sy = _viewport.height / rect.height;
    var scale = math.min(sx, sy) * 0.92;
    scale = scale.clamp(minScale, maxScale);

    final cx = rect.center.dx;
    final cy = rect.center.dy;

    final tx = (-cx * scale) + (_viewport.width / 2.0);
    final ty = (-cy * scale) + (_viewport.height / 2.0);

    final m = Matrix4.identity()..translate(tx, ty)..scale(scale);

    return MapTransformClamper.clampToViewport(
      transform: m,
      viewportSize: _viewport,
      contentSize: widget.map.canvasSize,
    );
  }

  void _animateTo(Matrix4 target) {
    _anim?.dispose();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));

    _matrixAnim = Matrix4Tween(begin: _tc.value, end: target).animate(
      CurvedAnimation(parent: _anim!, curve: Curves.easeInOutCubic),
    );

    _matrixAnim!.addListener(() {
      _tc.value = _matrixAnim!.value;
    });

    _anim!.forward();
  }

  // ==========================
  // Tap hit-testing
  // ==========================

  void _handleTapUp(TapUpDetails details) {
    if (widget.onCountryTap == null) return;

    // Convert screen point into map (scene) coordinates.
    final scene = _tc.toScene(details.localPosition);

    for (final c in widget.map.countries) {
      if (!c.bounds.contains(scene)) continue;
      if (c.path.contains(scene)) {
        widget.onCountryTap!(c.id);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewport = Size(constraints.maxWidth, constraints.maxHeight);
        final mapSize = widget.map.canvasSize;

        if (!_initialized && _viewport.width > 0 && _viewport.height > 0) {
          _initialized = true;

          // min zoom = fit width
          _fitWidthScale = _viewport.width / mapSize.width;

          // Start at fit-width, center vertically
          final scaledH = mapSize.height * _fitWidthScale;
          final dy = (_viewport.height - scaledH) / 2.0;

          _tc.value = Matrix4.identity()
            ..translate(0.0, dy)
            ..scale(_fitWidthScale);

          // Clamp once
          _tc.value = MapTransformClamper.clampToViewport(
            transform: _tc.value,
            viewportSize: _viewport,
            contentSize: mapSize,
          );
        }

        final minScale = _fitWidthScale;
        final maxScale = _fitWidthScale * 100.0;

        // ✅ This must already be ready if HomeShell used loadFromAssetWithAnchors
        final anchors = widget.map.labelAnchorById;

        final settings = AppSettingsScope.of(context);

        return ClipRect(
          child: Stack(
            children: [
              // 1) Base interactive map
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: _handleTapUp,
                child: InteractiveViewer(
                  transformationController: _tc,
                  constrained: false,
                  panEnabled: true,
                  scaleEnabled: true,
                  minScale: minScale,
                  maxScale: maxScale,
                  boundaryMargin: const EdgeInsets.all(100000),
                  clipBehavior: Clip.none,
                  child: ValueListenableBuilder<Set<String>>(
                    valueListenable: widget.selectedIds,
                    builder: (context, ids, _) {
                      return SizedBox(
                        width: mapSize.width,
                        height: mapSize.height,
                        child: CustomPaint(
                          painter: WorldMapPainter(
                            map: widget.map,
                            selectedIds: ids,
                            controller: _tc,
                            selectedColor: settings.selectedCountryColor,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 2) Labels overlay — ALWAYS (no async, no gating)
              AnimatedBuilder(
                animation: AppSettingsScope.of(context),
                builder: (context, _) {
                  final settings = AppSettingsScope.of(context);
                  if (!settings.showCountryLabels) return const SizedBox.shrink();

                  return IgnorePointer(
                    child: SizedBox.expand(
                      child: CustomPaint(
                        painter: WorldMapLabelsPainter(
                          map: widget.map,
                          controller: _tc,
                          anchors: anchors,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  bool _matrixAlmostEqual(Matrix4 a, Matrix4 b, {double eps = 1e-7}) {
    final sa = a.storage;
    final sb = b.storage;
    for (var i = 0; i < 16; i++) {
      if ((sa[i] - sb[i]).abs() > eps) return false;
    }
    return true;
  }
}
