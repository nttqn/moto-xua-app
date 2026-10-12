import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// Small drawing vocabulary shared by all the code-drawn art.
extension Draw on Canvas {
  void box(double x, double y, double w, double h, Color c, [double r = 0]) {
    final paint = Paint()..color = c;
    if (r <= 0) {
      drawRect(Rect.fromLTWH(x, y, w, h), paint);
    } else {
      drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)),
        paint,
      );
    }
  }

  void oval(double cx, double cy, double rx, double ry, Color c) {
    drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2),
      Paint()..color = c,
    );
  }

  /// [pts] is x0, y0, x1, y1, ...
  void poly(List<double> pts, Color c) {
    final path = Path()..moveTo(pts[0], pts[1]);
    for (var i = 2; i < pts.length; i += 2) {
      path.lineTo(pts[i], pts[i + 1]);
    }
    path.close();
    drawPath(path, Paint()..color = c);
  }

  void stroke(double x1, double y1, double x2, double y2, Color c, double w) {
    drawLine(
      Offset(x1, y1),
      Offset(x2, y2),
      Paint()
        ..color = c
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Text centred on ([cx], [cy]), squeezed to [maxW] if it would overrun.
  void label(
    String text,
    double cx,
    double cy,
    double size,
    Color c, {
    String family = 'Bungee',
    double? maxW,
    FontWeight weight = FontWeight.w400,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: family,
          fontSize: size,
          color: c,
          height: 1,
          fontWeight: weight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final squeeze = maxW != null && tp.width > maxW ? maxW / tp.width : 1.0;
    save();
    translate(cx, cy);
    scale(squeeze, 1);
    tp.paint(this, Offset(-tp.width / 2, -tp.height / 2));
    restore();
  }
}

/// Lighter for positive [f], darker for negative; [f] in -1..1.
Color shade(Color c, double f) => f >= 0
    ? Color.lerp(c, const Color(0xFFFFFFFF), f)!
    : Color.lerp(c, const Color(0xFF000000), -f)!;

/// One pre-drawn picture standing in the world.
class Sprite {
  Sprite(this.image, this.worldW, this.worldH);
  final ui.Image image;

  /// Metres.
  final double worldW;
  final double worldH;
}

/// Rasterises [draw], which works in a [dw] x [dh] design box, into an
/// image [pxW] pixels wide that stands [worldW] metres wide in the world.
Sprite makeSprite(
  double dw,
  double dh,
  double worldW,
  int pxW,
  void Function(Canvas c) draw,
) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final s = pxW / dw;
  canvas.scale(s);
  draw(canvas);
  final image = recorder.endRecording().toImageSync(pxW, (dh * s).ceil());
  return Sprite(image, worldW, worldW * dh / dw);
}
