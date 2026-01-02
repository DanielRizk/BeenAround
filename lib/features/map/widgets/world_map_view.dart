import 'package:flutter/material.dart';

import '../../../../shared/map/world_map_models.dart';
import '../presentation/utils/map_transform_clamper.dart';
import '../presentation/widgets/world_map_labels_painter.dart';
import 'world_map_painter.dart';

class WorldMapView extends StatefulWidget {
  final WorldMapData map;
  final ValueNotifier<Set<String>> selectedIds;

  const WorldMapView({
    super.key,
    required this.map,
    required this.selectedIds,
  });

  @override
  State<WorldMapView> createState() => _WorldMapViewState();
}

class _WorldMapViewState extends State<WorldMapView> {
  final TransformationController _tc = TransformationController();

  bool _initialized = false;
  bool _isClamping = false;

  Size _viewport = Size.zero;
  double _fitWidthScale = 1.0;

  @override
  void initState() {
    super.initState();
    _tc.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _tc.removeListener(_onTransformChanged);
    _tc.dispose();
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

        return ClipRect(
          child: Stack(
            children: [
              // 1) Base interactive map
              InteractiveViewer(
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
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 2) Labels overlay — ALWAYS (no async, no gating)
              IgnorePointer(
                child: SizedBox.expand(
                  child: CustomPaint(
                    painter: WorldMapLabelsPainter(
                      map: widget.map,
                      controller: _tc,
                      anchors: anchors,
                    ),
                  ),
                ),
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
