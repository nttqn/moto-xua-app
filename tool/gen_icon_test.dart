// Renders the launcher icon to assets/icon/icon.png.
//
// Run with: flutter test tool/gen_icon_test.dart
// then:     dart run flutter_launcher_icons
//
// It lives in a test because the Flutter test harness can rasterise
// without a device, and this machine has no image tooling.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moto_xua/core/bikes.dart';
import 'package:moto_xua/render/art_garage.dart';

void main() {
  test('launcher icon', () async {
    const s = 1024.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const box = Rect.fromLTWH(0, 0, s, s);

    // Full-bleed poster sunburst, the way old shop signs did it.
    canvas.drawRect(box, Paint()..color = const Color(0xFFF0C24B));
    const centre = Offset(s * 0.5, s * 0.60);
    final ray = Paint()..color = const Color(0xFFE8A62E);
    for (var k = 0; k < 16; k++) {
      final a = k * math.pi / 8;
      canvas.drawPath(
        Path()
          ..moveTo(centre.dx, centre.dy)
          ..lineTo(centre.dx + math.cos(a) * 1600, centre.dy + math.sin(a) * 1600)
          ..lineTo(centre.dx + math.cos(a + math.pi / 16) * 1600,
              centre.dy + math.sin(a + math.pi / 16) * 1600)
          ..close(),
        ray,
      );
    }
    canvas.drawCircle(centre, 330, Paint()..color = const Color(0xFFB3261E));
    canvas.drawCircle(centre, 300, Paint()..color = const Color(0xFFCC3A2A));

    // Road across the bottom.
    canvas.drawRect(const Rect.fromLTWH(0, 800, s, 224),
        Paint()..color = const Color(0xFF3A2A1E));
    canvas.drawRect(const Rect.fromLTWH(0, 800, s, 14),
        Paint()..color = const Color(0xFF2A1A12));
    for (var x = 40.0; x < s; x += 240) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x, 905, 140, 22), const Radius.circular(6)),
        Paint()..color = const Color(0xFFF3E9D2),
      );
    }

    // The little blue step-through, as big as it will go.
    canvas.save();
    canvas.translate(-38, 196);
    BikeSidePainter(BikeId.cub).paint(canvas, const Size(1100, 688));
    canvas.restore();

    final image = await recorder.endRecording().toImage(1024, 1024);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('assets/icon/icon.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
