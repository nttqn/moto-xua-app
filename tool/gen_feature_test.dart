// Renders Google Play's 1024 x 500 feature graphic to
// store/feature-graphic.png.
//
// Run with: flutter test tool/gen_feature_test.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moto_xua/core/bikes.dart';
import 'package:moto_xua/render/art_garage.dart';

const _ink = Color(0xFF2A1A12);

Future<void> _font(String family, String file) async {
  final bytes = File(file).readAsBytesSync();
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.view(bytes.buffer)));
  await loader.load();
}

/// Centred text with an optional outline and hard drop shadow.
void _text(Canvas canvas, String text, Offset centre, double size, Color color,
    {String family = 'Bungee', double outline = 0, double shadow = 0,
    double spacing = 0, FontWeight weight = FontWeight.w400}) {
  TextPainter make(Paint? foreground, Color? fill) => TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: family,
        fontSize: size,
        height: 1,
        letterSpacing: spacing,
        fontWeight: weight,
        color: fill,
        foreground: foreground,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final fill = make(null, color);
  final at = centre - Offset(fill.width / 2, fill.height / 2);
  if (outline > 0) {
    final stroke = make(
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = outline
        ..strokeJoin = StrokeJoin.round
        ..color = _ink,
      null,
    );
    if (shadow > 0) stroke.paint(canvas, at + Offset(shadow, shadow));
    stroke.paint(canvas, at);
  }
  fill.paint(canvas, at);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('feature graphic', () async {
    await _font('Bungee', 'assets/fonts/Bungee-Regular.ttf');
    await _font('BeVietnam', 'assets/fonts/BeVietnamPro-ExtraBold.ttf');

    const w = 1024.0, h = 500.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // The icon's sunburst, spread wide.
    canvas.drawRect(const Rect.fromLTWH(0, 0, w, h),
        Paint()..color = const Color(0xFFF0C24B));
    const centre = Offset(w / 2, 400);
    final ray = Paint()..color = const Color(0xFFE8A62E);
    for (var k = 0; k < 20; k++) {
      final a = k * math.pi / 10;
      canvas.drawPath(
        Path()
          ..moveTo(centre.dx, centre.dy)
          ..lineTo(centre.dx + math.cos(a) * 1400, centre.dy + math.sin(a) * 1400)
          ..lineTo(centre.dx + math.cos(a + math.pi / 20) * 1400,
              centre.dy + math.sin(a + math.pi / 20) * 1400)
          ..close(),
        ray,
      );
    }
    canvas.drawCircle(centre, 250, Paint()..color = const Color(0xFFB3261E));
    canvas.drawCircle(centre, 228, Paint()..color = const Color(0xFFCC3A2A));

    // Road.
    canvas.drawRect(const Rect.fromLTWH(0, 428, w, 72),
        Paint()..color = const Color(0xFF3A2A1E));
    canvas.drawRect(
        const Rect.fromLTWH(0, 428, w, 6), Paint()..color = _ink);
    for (var x = 30.0; x < w; x += 150) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x, 466, 84, 10), const Radius.circular(4)),
        Paint()..color = const Color(0xFFF3E9D2),
      );
    }

    // Three of the bikes nose to tail.
    void bike(BikeId id, double x, double width) {
      final size = Size(width, width * 125 / 200);
      canvas.save();
      // The painter's wheels touch down at 116/125 of its box.
      canvas.translate(x, 440 - size.height * 116 / 125);
      BikeSidePainter(id).paint(canvas, size);
      canvas.restore();
    }

    bike(BikeId.sport, 22, 300);
    bike(BikeId.x67, 702, 300);
    bike(BikeId.cub, 332, 360);

    // Title block.
    _text(canvas, 'XE XƯA', const Offset(w / 2, 92), 124,
        const Color(0xFFF0C24B), outline: 16, shadow: 7, spacing: 4);
    const plaque = Rect.fromLTWH(w / 2 - 190, 168, 380, 42);
    canvas.drawRRect(
        RRect.fromRectAndRadius(plaque.inflate(4), const Radius.circular(10)),
        Paint()..color = _ink);
    canvas.drawRRect(
        RRect.fromRectAndRadius(plaque, const Radius.circular(7)),
        Paint()..color = const Color(0xFFB3261E));
    _text(canvas, 'ĐUA XE MÁY MỘT THỜI', plaque.center, 23,
        const Color(0xFFFFF3C4),
        family: 'BeVietnam', weight: FontWeight.w800, spacing: 2.5);

    final image = await recorder.endRecording().toImage(1024, 500);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('store/feature-graphic.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
