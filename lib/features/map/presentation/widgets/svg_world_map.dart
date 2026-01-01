import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../data/svg_map_repository.dart';

class SvgWorldMap extends StatefulWidget {
  final String assetPath;
  final ValueListenable<double> scaleListenable;

  /// true while user is pinching/panning
  final ValueListenable<bool> isInteracting;

  /// desired on-screen border thickness
  final double baseBorderWidth;

  const SvgWorldMap({
    super.key,
    required this.assetPath,
    required this.scaleListenable,
    required this.isInteracting,
    this.baseBorderWidth = 0.5,
  });

  @override
  State<SvgWorldMap> createState() => _SvgWorldMapState();
}

class _SvgWorldMapState extends State<SvgWorldMap> {
  final _repo = SvgMapRepository();

  String? _templateSvg; // contains __SW__
  String? _currentSvg;

  @override
  void initState() {
    super.initState();
    widget.scaleListenable.addListener(_onScaleMaybe);
    widget.isInteracting.addListener(_onInteractionChanged);
    _loadTemplate();
  }

  @override
  void didUpdateWidget(covariant SvgWorldMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.scaleListenable != widget.scaleListenable) {
      oldWidget.scaleListenable.removeListener(_onScaleMaybe);
      widget.scaleListenable.addListener(_onScaleMaybe);
    }

    if (oldWidget.isInteracting != widget.isInteracting) {
      oldWidget.isInteracting.removeListener(_onInteractionChanged);
      widget.isInteracting.addListener(_onInteractionChanged);
    }

    if (oldWidget.assetPath != widget.assetPath) {
      _templateSvg = null;
      _currentSvg = null;
      _loadTemplate();
    }
  }

  @override
  void dispose() {
    widget.scaleListenable.removeListener(_onScaleMaybe);
    widget.isInteracting.removeListener(_onInteractionChanged);
    super.dispose();
  }

  Future<void> _loadTemplate() async {
    final template = await _repo.loadWorldMapTemplate(widget.assetPath);
    if (!mounted) return;

    setState(() {
      _templateSvg = template;
    });

    // initial apply
    _applyConstantBorderNow();
  }

  void _onScaleMaybe() {
    // Only update borders while NOT interacting (optional).
    // This keeps the zoom buttery smooth.
    if (widget.isInteracting.value) return;
    _applyConstantBorderNow();
  }

  void _onInteractionChanged() {
    // When interaction ends, apply constant borders ONCE.
    if (!widget.isInteracting.value) {
      _applyConstantBorderNow();
    }
  }

  void _applyConstantBorderNow() {
    if (_templateSvg == null) return;

    final scale = widget.scaleListenable.value;
    final safeScale = math.max(scale, 0.0001);

    // inverse-scale stroke so it appears constant on screen
    final stroke = widget.baseBorderWidth / safeScale;

    final svg = _templateSvg!.replaceAll('__SW__', stroke.toStringAsFixed(4));

    setState(() {
      _currentSvg = svg;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentSvg == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, c) {
        return SvgPicture.string(
          _currentSvg!,
          width: c.maxWidth,
          height: c.maxHeight,
          fit: BoxFit.contain,
          alignment: Alignment.center,
        );
      },
    );
  }
}
