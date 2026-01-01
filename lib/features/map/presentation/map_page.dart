import 'package:flutter/material.dart';
import 'widgets/bounded_interactive_map.dart';
import 'widgets/svg_world_map.dart';
import 'widgets/map_camera_controller.dart';
import '../domain/map_region.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final _cameraController = MapCameraController();
  final ValueNotifier<double> _scale = ValueNotifier(1.0);
  final ValueNotifier<bool> _isInteracting = ValueNotifier(false);


  @override
  void initState() {
    super.initState();
    _cameraController.focusOnRegion(MapRegion.africa); // queued until map attaches
  }

  @override
  void dispose() {
    _scale.dispose();
    _isInteracting.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: BoundedInteractiveMap(
          controller: _cameraController,
          scaleNotifier: _scale,
          isInteractingNotifier: _isInteracting,
          child: SvgWorldMap(
            assetPath: 'assets/maps/world.svg',
            scaleListenable: _scale,
            isInteracting: _isInteracting,
            baseBorderWidth: 0.5,
          ),
        ),
      ),
    );
  }
}