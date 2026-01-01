import 'package:flutter/material.dart';
import 'map_camera_controller.dart';

/// A zoomable/pannable viewer that clamps translation so the content cannot be
/// dragged completely off-screen.
/// It also supports programmatic camera moves via [MapCameraController].
class BoundedInteractiveMap extends StatefulWidget {
  final Widget child;

  /// If you know your SVG's natural aspect ratio you can tune this later.
  final double minScale;
  final double maxScale;

  /// Optional controller to programmatically move the camera.
  final MapCameraController? controller;

  /// Optional initial focus (normalized 0..1 inside the child)
  /// Example (Africa-ish): Offset(0.55, 0.60)
  final Offset? initialFocalPoint;

  /// Initial zoom scale used when [initialFocalPoint] is provided.
  final double initialScale;

  final ValueNotifier<double>? scaleNotifier;
  final ValueNotifier<bool>? isInteractingNotifier;


  const BoundedInteractiveMap({
    super.key,
    required this.child,
    this.minScale = 1.0,
    this.maxScale = 100.0,
    this.controller,
    this.initialFocalPoint,
    this.initialScale = 2.5,
    this.scaleNotifier,
    this.isInteractingNotifier,
  });

  @override
  State<BoundedInteractiveMap> createState() => _BoundedInteractiveMapState();
}

class _BoundedInteractiveMapState extends State<BoundedInteractiveMap> {
  final TransformationController _controller = TransformationController();

  // These come from LayoutBuilder
  Size _viewportSize = Size.zero;

  // These come from the child's layout size (after it’s built)
  Size _childSize = Size.zero;

  bool _initialApplied = false;

  @override
  void initState() {
    super.initState();
    widget.controller?.attach(focusFn: _focusOnNormalized);
    _controller.addListener(_clampTransform);
  }


  @override
  void didUpdateWidget(covariant BoundedInteractiveMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If controller instance changed, attach again.
    if (oldWidget.controller != widget.controller) {
      widget.controller?.attach(focusFn: _focusOnNormalized);
    }

    // If initial focus params changed, allow re-apply (optional behavior).
    if (oldWidget.initialFocalPoint != widget.initialFocalPoint ||
        oldWidget.initialScale != widget.initialScale) {
      _initialApplied = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyInitialIfPossible();
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_clampTransform);
    _controller.dispose();
    super.dispose();
  }

  // -------------------------
  // Public API for controller
  // -------------------------

  /// Focus the map on a normalized point (0..1 inside the child) with a given scale.
  bool _focusOnNormalized(Offset normalizedFocalPoint, double scale) {
    if (_viewportSize == Size.zero || _childSize == Size.zero) return false;

    final clampedScale = scale.clamp(widget.minScale, widget.maxScale);

    final focalX = _childSize.width * normalizedFocalPoint.dx * clampedScale;
    final focalY = _childSize.height * normalizedFocalPoint.dy * clampedScale;

    final tx = (_viewportSize.width / 2) - focalX;
    final ty = (_viewportSize.height / 2) - focalY;

    _controller.value = Matrix4.identity()
      ..translate(tx, ty)
      ..scale(clampedScale);

    _clampTransform();
    return true;
  }

  void _applyInitialIfPossible() {
    if (_initialApplied) return;
    if (widget.initialFocalPoint == null) return;
    if (_viewportSize == Size.zero || _childSize == Size.zero) return;

    _focusOnNormalized(widget.initialFocalPoint!, widget.initialScale);
    _initialApplied = true;
  }

  // -------------------------
  // Clamp logic
  // -------------------------

  void _clampTransform() {
    if (_viewportSize == Size.zero || _childSize == Size.zero) return;

    final m = _controller.value;

    // Current scale (assumes uniform scaling)
    final scale = m.getMaxScaleOnAxis().clamp(widget.minScale, widget.maxScale);

    widget.scaleNotifier?.value = scale;

    // If scale got out of bounds, normalize it
    if (scale != m.getMaxScaleOnAxis()) {
      final normalized = Matrix4.identity()
        ..translate(m.storage[12], m.storage[13])
        ..scale(scale);
      _controller.value = normalized;
      return;
    }

    // Visible size of the scaled child
    final scaledChildW = _childSize.width * scale;
    final scaledChildH = _childSize.height * scale;

    // Translation
    final tx = m.storage[12];
    final ty = m.storage[13];

    // We want to clamp so at least some part of the map stays visible.
    // If the scaled child is smaller than the viewport, we center it.
    double minTx, maxTx, minTy, maxTy;

    if (scaledChildW <= _viewportSize.width) {
      final centered = (_viewportSize.width - scaledChildW) / 2;
      minTx = centered;
      maxTx = centered;
    } else {
      minTx = _viewportSize.width - scaledChildW;
      maxTx = 0.0;
    }

    if (scaledChildH <= _viewportSize.height) {
      final centered = (_viewportSize.height - scaledChildH) / 2;
      minTy = centered;
      maxTy = centered;
    } else {
      minTy = _viewportSize.height - scaledChildH;
      maxTy = 0.0;
    }

    final clampedTx = tx.clamp(minTx, maxTx);
    final clampedTy = ty.clamp(minTy, maxTy);

    if (clampedTx != tx || clampedTy != ty) {
      final corrected = Matrix4.identity()
        ..translate(clampedTx, clampedTy)
        ..scale(scale);

      // Prevent “feedback loop” jitter by only setting when needed
      _controller.value = corrected;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);

        // In case viewport changed (rotation etc.), try initial again if needed.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _applyInitialIfPossible();
        });

        return InteractiveViewer(
          transformationController: _controller,
          minScale: widget.minScale,
          maxScale: widget.maxScale,
          panEnabled: true,
          scaleEnabled: true,
          boundaryMargin: EdgeInsets.zero,
          clipBehavior: Clip.hardEdge,

          onInteractionStart: (_) => widget.isInteractingNotifier?.value = true,
          onInteractionEnd: (_) => widget.isInteractingNotifier?.value = false,

          child: _Measurable(
            onSize: (s) {
              // Track the child’s size; this enables correct clamping.
              if (s != _childSize) {
                setState(() => _childSize = s);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  widget.controller?.flushPending(); // ✅ THIS is the key line
                  _clampTransform();
                });
              }
            },
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Measures the rendered size of a widget.
class _Measurable extends StatefulWidget {
  final Widget child;
  final ValueChanged<Size> onSize;

  const _Measurable({required this.child, required this.onSize});

  @override
  State<_Measurable> createState() => _MeasurableState();
}

class _MeasurableState extends State<_Measurable> {
  final _key = GlobalKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifySize());
  }

  @override
  void didUpdateWidget(covariant _Measurable oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifySize());
  }

  void _notifySize() {
    final ctx = _key.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    widget.onSize(box.size);
  }

  @override
  Widget build(BuildContext context) {
    // Using Align keeps natural size (good for SVG sizing decisions).
    return SizedBox.expand(
      child: Container(key: _key, child: widget.child),
    );
  }
}
