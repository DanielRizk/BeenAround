import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../data/svg_map_repository.dart';

class SvgWorldMap extends StatefulWidget {
  final String assetPath;

  // current zoom scale
  final ValueListenable<double> scaleListenable;

  // true while user is pinching/panning
  final ValueListenable<bool> isInteracting;

  // selected country ids (e.g. {"DE","EG"})
  final ValueListenable<Set<String>> selectedIds;

  // desired on-screen border thickness
  final double baseBorderWidth;

  const SvgWorldMap({
    super.key,
    required this.assetPath,
    required this.scaleListenable,
    required this.isInteracting,
    required this.selectedIds,
    this.baseBorderWidth = 0.5,
  });

  @override
  State<SvgWorldMap> createState() => _SvgWorldMapState();
}

class _SvgWorldMapState extends State<SvgWorldMap> {
  final _repo = SvgMapRepository();

  String? _templateWithSelection; // contains __SW__
  String? _currentSvg;            // __SW__ resolved

  @override
  void initState() {
    super.initState();
    widget.selectedIds.addListener(_onSelectionChanged);
    widget.isInteracting.addListener(_onInteractionChanged);
    _rebuildTemplateForSelection(); // initial
  }

  @override
  void didUpdateWidget(covariant SvgWorldMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedIds != widget.selectedIds) {
      oldWidget.selectedIds.removeListener(_onSelectionChanged);
      widget.selectedIds.addListener(_onSelectionChanged);
    }

    if (oldWidget.isInteracting != widget.isInteracting) {
      oldWidget.isInteracting.removeListener(_onInteractionChanged);
      widget.isInteracting.addListener(_onInteractionChanged);
    }

    if (oldWidget.assetPath != widget.assetPath) {
      _templateWithSelection = null;
      _currentSvg = null;
      _rebuildTemplateForSelection();
    }
  }

  @override
  void dispose() {
    widget.selectedIds.removeListener(_onSelectionChanged);
    widget.isInteracting.removeListener(_onInteractionChanged);
    super.dispose();
  }

  void _onSelectionChanged() {
    // Rebuild template when selection changes (rare, user-driven)
    _rebuildTemplateForSelection();
  }

  void _onInteractionChanged() {
    // When interaction ends, apply constant border correction once
    if (!widget.isInteracting.value) {
      _applyStrokeNow();
    }
  }

  Future<void> _rebuildTemplateForSelection() async {
    final template = await _repo.buildTemplateSvg(
      widget.assetPath,
      selectedIds: widget.selectedIds.value,
    );

    if (!mounted) return;

    setState(() {
      _templateWithSelection = template;
    });

    // After template rebuild, resolve stroke once
    _applyStrokeNow();
  }

  void _applyStrokeNow() {
    if (_templateWithSelection == null) return;

    final scale = widget.scaleListenable.value;
    final safeScale = math.max(scale, 0.0001);

    final stroke = widget.baseBorderWidth / safeScale;
    final resolved = _templateWithSelection!.replaceAll(
      '__SW__',
      stroke.toStringAsFixed(4),
    );

    setState(() {
      _currentSvg = resolved;
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
