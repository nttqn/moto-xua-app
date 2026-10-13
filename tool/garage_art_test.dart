// Renders every bike to PNGs for eyeballing:
//   flutter test tool/garage_art_test.dart
// writes build/garage_art.png (side views) and build/rider_art.png (the
// behind and head-on sprites used on the road).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moto_xua/core/bikes.dart';
import 'package:moto_xua/render/art_garage.dart';
import 'package:moto_xua/render/art_vehicles.dart';

Future<void> _save(ui.PictureRecorder recorder, int w, int h, String path) async {
  final image = await recorder.endRecording().toImage(w, h);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  test('art sheets', () async {
    const cell = Size(800, 500);
    const columns = 2;
    final rows = (BikeId.values.length / columns).ceil();
    final w = (cell.width * columns).round(), h = (cell.height * rows).round();
    var recorder = ui.PictureRecorder();
    var canvas = Canvas(recorder);
    canvas.drawRect(Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
        Paint()..color = const Color(0xFFE4D5B3));
    for (final b in BikeId.values) {
      canvas.save();
      canvas.translate(
          (b.index % columns) * cell.width, (b.index ~/ columns) * cell.height);
      BikeSidePainter(b).paint(canvas, cell);
      canvas.restore();
    }
    await _save(recorder, w, h, 'build/garage_art.png');

    recorder = ui.PictureRecorder();
    canvas = Canvas(recorder);
    final n = BikeId.values.length;
    canvas.drawRect(Rect.fromLTWH(0, 0, n * 170.0, 540),
        Paint()..color = const Color(0xFF5E5F63));
    for (final b in BikeId.values) {
      for (final front in [false, true]) {
        final img = buildRider(b, front ? 1 + b.index % 5 : 0, front: front).image;
        canvas.drawImage(
            img, Offset(10 + b.index * 170.0, front ? 280 : 10), Paint());
      }
    }
    await _save(recorder, n * 170, 540, 'build/rider_art.png');
  });
}
