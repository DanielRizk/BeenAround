import 'package:flutter/material.dart';
import 'svg_world_loader.dart';
import 'svg_world_painter.dart';

import '../../core/country.dart';
import '../../core/country_repo.dart';
import 'widgets/country_picker_sheet.dart';

class MapsTab extends StatefulWidget {
  const MapsTab({super.key});

  @override
  State<MapsTab> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapsTab> with SingleTickerProviderStateMixin {
  SvgWorld? _world;

  List<Country> _countries = const [];
  Map<String, String> _svgToIso2 = const {}; // svgId -> ISO2
  late Map<String, Set<String>> _iso2ToSvgIds = {}; // ISO2 -> {svgId,...}

  final Set<String> _visitedIso2 = {}; // stable storage (ISO2)
  double _currentScale = 1.0;

  final TransformationController _tc = TransformationController();

  late final AnimationController _animCtrl;
  Animation<Matrix4>? _anim;

  String? _focusedSvgId;

  static const double _minScale = 1.0;
  static const double _maxScale = 100.0; // you can keep it high

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _tc.addListener(() {
      final s = _tc.value.getMaxScaleOnAxis();

      // Track zoom for painter label logic
      if (s != _currentScale) {
        setState(() => _currentScale = s);
      }

      // If user zooms back out near normal view -> exit "focused" mode
      if (_focusedSvgId != null && s <= 1.05) {
        setState(() => _focusedSvgId = null);
      }
    });

    _load();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _tc.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final w = await loadWorldSvg('assets/maps/world.svg');
    final countries = await CountryRepo.loadCountries('assets/data/countries.json');
    final svgToIso2 = await CountryRepo.loadSvgToIso2('assets/data/svg_to_iso2.json');

    final iso2ToSvg = <String, Set<String>>{};
    svgToIso2.forEach((svgId, iso2) {
      iso2ToSvg.putIfAbsent(iso2, () => <String>{}).add(svgId);
    });

    setState(() {
      _world = w;
      _countries = countries;
      _svgToIso2 = svgToIso2;
      _iso2ToSvgIds = iso2ToSvg;
    });
  }

  // Painter still needs SVG ids for visited fill
  Set<String> get _visitedSvgIds {
    final out = <String>{};
    for (final iso2 in _visitedIso2) {
      out.addAll(_iso2ToSvgIds[iso2] ?? const <String>{});
    }
    return out;
  }

  // Provide labels per svgId
  Map<String, String> get _svgIdToDisplayName {
    final map = <String, String>{};
    for (final entry in _svgToIso2.entries) {
      final svgId = entry.key;
      final iso2 = entry.value;
      final name = _countries.firstWhere(
            (c) => c.iso2 == iso2,
        orElse: () => Country(iso2: iso2, name: iso2),
      ).name;
      map[svgId] = name;
    }
    return map;
  }

  // ---------- Hit test in SVG coords ----------
  String? _hitTestCountry(Offset localPos, Size size) {
    final world = _world!;
    final scaleX = size.width / world.viewBox.width;
    final scaleY = size.height / world.viewBox.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    final dx = (size.width - world.viewBox.width * scale) / 2.0;
    final dy = (size.height - world.viewBox.height * scale) / 2.0;

    // Undo InteractiveViewer transform
    final inv = Matrix4.inverted(_tc.value);
    final p = MatrixUtils.transformPoint(inv, localPos);

    // Undo painter fit transform -> back to SVG coords
    final x = (p.dx - dx) / scale + world.viewBox.left;
    final y = (p.dy - dy) / scale + world.viewBox.top;

    final svgPoint = Offset(x, y);

    for (final c in world.countries.reversed) {
      if (c.path.contains(svgPoint)) return c.id;
    }
    return null;
  }

  // ---------- Convert SVG rect -> local (painter) rect ----------
  Rect _svgRectToLocalRect(Rect svgRect, Size size) {
    final world = _world!;
    final scaleX = size.width / world.viewBox.width;
    final scaleY = size.height / world.viewBox.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    final dx = (size.width - world.viewBox.width * scale) / 2.0;
    final dy = (size.height - world.viewBox.height * scale) / 2.0;

    final left = (svgRect.left - world.viewBox.left) * scale + dx;
    final top = (svgRect.top - world.viewBox.top) * scale + dy;
    final right = (svgRect.right - world.viewBox.left) * scale + dx;
    final bottom = (svgRect.bottom - world.viewBox.top) * scale + dy;

    return Rect.fromLTRB(left, top, right, bottom);
  }

  void _onAnimTick() {
    final a = _anim;
    if (a == null) return;
    _tc.value = a.value;
  }

  void _animateTo(Matrix4 target) {
    _animCtrl.stop();
    _animCtrl.reset();

    final begin = _tc.value;
    _anim = Matrix4Tween(begin: begin, end: target).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
    );

    _animCtrl.removeListener(_onAnimTick);
    _animCtrl.addListener(_onAnimTick);

    _animCtrl.forward();
  }

  // ---------- Zoom to country ----------
  void _zoomToCountry(String svgId, Size size) {
    final world = _world!;
    final c = world.countries.firstWhere((e) => e.id == svgId);
    final svgBounds = c.path.getBounds();
    final localBounds = _svgRectToLocalRect(svgBounds, size);

    // Fill screen aggressively (tiny padding)
    const padding = 2.0;
    const fill = 0.995;
    final padded = localBounds.inflate(padding);

    final scaleX = (size.width / padded.width) * fill;
    final scaleY = (size.height / padded.height) * fill;
    var targetScale = scaleX < scaleY ? scaleX : scaleY;
    targetScale = targetScale.clamp(_minScale, _maxScale);

    final center = padded.center;
    final tx = (size.width / 2) - targetScale * center.dx;
    final ty = (size.height / 2) - targetScale * center.dy;

    final target = Matrix4.identity()
      ..translate(tx, ty)
      ..scale(targetScale);

    setState(() => _focusedSvgId = svgId); // hide labels while focused
    _animateTo(target);
  }

  void _resetZoom() {
    _animateTo(Matrix4.identity());
    setState(() => _focusedSvgId = null);
  }

  Future<void> _openCountryPicker() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => CountryPickerSheet(
        countries: _countries,
        visitedIso2: _visitedIso2,
        onChanged: (newSet) {
          setState(() {
            _visitedIso2
              ..clear()
              ..addAll(newSet);
          });

          // If focused country becomes unvisited -> drop focus
          final focused = _focusedSvgId;
          if (focused != null && !_visitedSvgIds.contains(focused)) {
            setState(() => _focusedSvgId = null);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final world = _world;
    if (world == null) return const Center(child: CircularProgressIndicator());

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return PopScope(
          // Back button: if focused, exit focus first.
          canPop: _focusedSvgId == null,
          onPopInvoked: (didPop) {
            if (!didPop && _focusedSvgId != null) {
              _resetZoom();
            }
          },
          child: Scaffold(
            body: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: (d) {
                final svgId = _hitTestCountry(d.localPosition, size);
                if (svgId == null) return;

                // Only visited countries trigger auto zoom
                if (!_visitedSvgIds.contains(svgId)) return;

                _zoomToCountry(svgId, size);
              },
              child: InteractiveViewer(
                transformationController: _tc,
                minScale: _minScale,
                maxScale: _maxScale,

                // Critical: allow centering tiny countries at big zoom
                boundaryMargin: const EdgeInsets.all(double.infinity),
                clipBehavior: Clip.none,

                child: CustomPaint(
                  size: size,
                  painter: SvgWorldPainter(
                    world: world,
                    visitedCountries: _visitedSvgIds,
                    viewportScale: _currentScale,
                    showLabels: _focusedSvgId == null,
                    countryLabels: _svgIdToDisplayName,
                  ),
                ),
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: _openCountryPicker,
              child: const Icon(Icons.add),
            ),
          ),
        );
      },
    );
  }
}
