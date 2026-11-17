// Renders every paint job, hat and shirt for eyeballing:
//   flutter test tool/cosmetics_art_test.dart
// writes build/paint_art.png (side views, one row per bike, one column
// per paint) and build/outfit_art.png (hats head-on, shirts from behind,
// plus the picker icons).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moto_xua/core/bikes.dart';
import 'package:moto_xua/core/cosmetics.dart';
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
  test('cosmetics sheets', () async {
    const cell = Size(400, 250);
    final cols = 4, rows = BikeId.values.length;
    var recorder = ui.PictureRecorder();
    var canvas = Canvas(recorder);
    canvas.drawRect(Rect.fromLTWH(0, 0, cell.width * cols, cell.height * rows),
        Paint()..color = const Color(0xFFE4D5B3));
    for (final b in BikeId.values) {
      for (var i = 0; i < liveries[b]!.length; i++) {
        canvas.save();
        canvas.translate(i * cell.width, b.index * cell.height);
        BikeSidePainter(b, livery: i).paint(canvas, cell);
        canvas.restore();
      }
    }
    await _save(recorder, (cell.width * cols).round(),
        (cell.height * rows).round(), 'build/paint_art.png');

    recorder = ui.PictureRecorder();
    canvas = Canvas(recorder);
    final n = shirts.length;
    canvas.drawRect(Rect.fromLTWH(0, 0, n * 170.0, 940),
        Paint()..color = const Color(0xFF5E5F63));
    for (var i = 0; i < hats.length; i++) {
      final img = buildRider(BikeId.cub, RiderLook(hat: i), front: true).image;
      canvas.drawImage(img, Offset(10 + i * 170.0, 10), Paint());
      final back = buildRider(BikeId.cub, RiderLook(hat: i, paint: 1)).image;
      canvas.drawImage(back, Offset(10 + i * 170.0, 270), Paint());
    }
    for (var i = 0; i < n; i++) {
      final img = buildRider(BikeId.x67, RiderLook(shirt: i, hat: 4)).image;
      canvas.drawImage(img, Offset(10 + i * 170.0, 530), Paint());
    }
    for (var i = 0; i < hats.length; i++) {
      canvas.save();
      canvas.translate(10 + i * 170.0, 790);
      canvas.scale(2.5);
      canvas.drawRect(const Rect.fromLTWH(0, 0, 30, 30),
          Paint()..color = const Color(0xFFF3E9D2));
      paintHatIcon(canvas, i);
      canvas.restore();
    }
    for (var i = 0; i < n; i++) {
      canvas.save();
      canvas.translate(90 + i * 170.0, 790);
      canvas.scale(2.5);
      canvas.drawRect(const Rect.fromLTWH(0, 0, 30, 30),
          Paint()..color = const Color(0xFFF3E9D2));
      paintShirtIcon(canvas, shirts[i]);
      canvas.restore();
    }
    await _save(recorder, n * 170, 940, 'build/outfit_art.png');
  });
}
