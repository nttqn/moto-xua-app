// Renders the four garage pictures to one PNG for eyeballing:
//   flutter test tool/garage_art_test.dart
// writes build/garage_art.png.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moto_xua/core/bikes.dart';
import 'package:moto_xua/render/art_garage.dart';

void main() {
  test('garage art sheet', () async {
    const cell = Size(800, 500);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 1600, 1000),
        Paint()..color = const Color(0xFFE4D5B3));
    for (final b in BikeId.values) {
      canvas.save();
      canvas.translate((b.index % 2) * cell.width, (b.index ~/ 2) * cell.height);
      BikeSidePainter(b).paint(canvas, cell);
      canvas.restore();
    }
    final image = await recorder.endRecording().toImage(1600, 1000);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final out = File('build/garage_art.png')..createSync(recursive: true);
    out.writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
