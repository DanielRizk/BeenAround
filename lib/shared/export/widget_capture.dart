import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

Future<Uint8List?> captureRepaintBoundary(GlobalKey key) async {
  final context = key.currentContext;
  if (context == null) return null;

  final renderObject = context.findRenderObject();
  if (renderObject is! RenderRepaintBoundary) return null;

  final ui.Image image = await renderObject.toImage(pixelRatio: 5.0);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData?.buffer.asUint8List();
}
