import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../core/bikes.dart';
import 'draw.dart';

const _tyre = Color(0xFF1B1B1B);
const _chrome = Color(0xFFC9CED2);
const _chromeDark = Color(0xFF8D9499);
const _engine = Color(0xFFAEB4B8);
const _black = Color(0xFF1E1E22);
const _lens = Color(0xFFFFF3C4);
const _red = Color(0xFFD6312B);

/// A bike standing side-on in the garage, nose to the right. Drawn as
/// vectors in a 200 x 125 box so it stays crisp at any size.
class BikeSidePainter extends CustomPainter {
  const BikeSidePainter(this.bike);
  final BikeId bike;

  static const double _w = 200;
  static const double _h = 125;

  // Axles, shared by all four so they line up when swiping.
  static const double _rx = 48, _fx = 156, _ay = 92;

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width / _w, size.height / _h);
    canvas.save();
    canvas.translate((size.width - _w * s) / 2, (size.height - _h * s) / 2);
    canvas.scale(s);
    canvas.oval(102, 117, 82, 5, const Color(0x33000000));
    switch (bike) {
      case BikeId.cub:
        _cub(canvas);
      case BikeId.wave:
        _wave(canvas);
      case BikeId.dream:
        _dream(canvas);
      case BikeId.x67:
        _x67(canvas);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(BikeSidePainter old) => old.bike != bike;

  static void _wheel(Canvas c, double cx) {
    c.oval(cx, _ay, 24, 24, _tyre);
    c.oval(cx, _ay, 18.5, 18.5, _chrome);
    c.oval(cx, _ay, 16.5, 16.5, const Color(0xFFE9E2CE));
    for (var k = 0; k < 18; k++) {
      final a = k * math.pi / 9;
      c.stroke(cx, _ay, cx + math.cos(a) * 17, _ay + math.sin(a) * 17,
          _chromeDark, 0.5);
    }
    c.oval(cx, _ay, 5, 5, _chromeDark);
    c.oval(cx, _ay, 2, 2, _black);
  }

  /// A mudguard: part of a ring around a wheel, angles in degrees
  /// clockwise from three o'clock.
  static void _guard(Canvas c, double cx, double start, double sweep,
      Color color, {double r = 27.5, double width = 5}) {
    c.drawArc(
      Rect.fromCircle(center: Offset(cx, _ay), radius: r),
      start * math.pi / 180,
      sweep * math.pi / 180,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  static void _shape(Canvas c, Color color, void Function(Path p) build) {
    final p = Path();
    build(p);
    p.close();
    c.drawPath(p, Paint()..color = color);
  }

  static void _shock(Canvas c, double x1, double y1, double x2, double y2,
      {bool bare = false}) {
    c.stroke(x1, y1, x2, y2, bare ? _chromeDark : _black, 4.2);
    if (bare) {
      // Exposed spring coils.
      for (var k = 1; k < 8; k++) {
        final t = k / 8;
        final x = x1 + (x2 - x1) * t, y = y1 + (y2 - y1) * t;
        c.stroke(x - 2.6, y - 0.6, x + 2.6, y + 0.6, _chrome, 1.1);
      }
    } else {
      c.stroke(x1, y1, (x1 + x2) / 2, (y1 + y2) / 2, _chrome, 2.2);
    }
  }

  static void _bars(Canvas c, double hx, double hy, {bool low = false}) {
    // Mirror on its stalk, then bar and grip.
    c.stroke(hx - 6, hy - 2, hx - 9, hy - 17, _chromeDark, 1.2);
    c.oval(hx - 10, hy - 20, 4.6, 3.6, _chrome);
    c.oval(hx - 10, hy - 20, 3.4, 2.5, const Color(0xFFA9C7D2));
    c.stroke(hx, hy, hx - 12, hy - (low ? 1 : 5), _chromeDark, 2.4);
    c.stroke(hx - 9, hy - (low ? 0.8 : 3.8), hx - 16, hy - (low ? 1.4 : 6.6),
        _black, 3.4);
  }

  static void _plate(Canvas c, double x, double y) {
    c.save();
    c.translate(x, y);
    c.rotate(-0.25);
    c.box(-1, 0, 3, 9, const Color(0xFFF4F4F0), 0.6);
    c.restore();
  }

  /// The pressed-steel underbone shared by the three step-throughs.
  static void _underbone(Canvas c, Color body) {
    _shape(c, body, (p) {
      p.moveTo(122, 52);
      p.quadraticBezierTo(112, 76, 92, 76);
      p.quadraticBezierTo(80, 62, 62, 60);
      p.lineTo(60, 72);
      p.quadraticBezierTo(82, 76, 90, 88);
      p.lineTo(116, 88);
      p.quadraticBezierTo(126, 70, 128, 52);
    });
  }

  static void _flatEngine(Canvas c, {Color cases = _engine}) {
    c.box(80, 80, 26, 15, cases, 5);
    c.box(104, 82, 13, 10, shade(cases, -0.12), 2);
    for (var x = 106.0; x < 117; x += 2.4) {
      c.stroke(x, 82.5, x, 91.5, shade(cases, -0.35), 0.6);
    }
    c.oval(90, 87.5, 5.5, 5.5, shade(cases, 0.18));
    c.oval(90, 87.5, 2, 2, shade(cases, -0.3));
    // Kick-start and footpeg.
    c.stroke(86, 92, 78, 104, _chromeDark, 1.6);
    c.stroke(94, 97, 102, 97, _black, 2.6);
  }

  static void _cub(Canvas c) {
    const body = Color(0xFF2F6FB0);
    const cream = Color(0xFFF2EFE6);
    // Far-side bits first.
    c.stroke(_fx, _ay, 139, 40, _chromeDark, 4);
    _wheel(c, _rx);
    _wheel(c, _fx);
    _guard(c, _fx, 196, 150, body);
    _guard(c, _rx, 178, 118, body);
    c.stroke(_fx - 2, _ay - 2, 141, 46, body, 6);
    // Enclosed chain case, the Cub signature.
    c.stroke(_rx, _ay + 1, 84, _ay - 1, cream, 10);
    c.stroke(_rx, _ay + 1, 84, _ay - 1, shade(cream, -0.12), 1);
    _flatEngine(c);
    // Slim silencer.
    c.stroke(100, 98, 70, 101, _chromeDark, 2.4);
    c.stroke(72, 101, 30, 101, _chrome, 6.4);
    c.oval(29, 101, 1.6, 2.2, _black);
    _shock(c, 54, 62, 49, 88);
    // Rear body and tail.
    _shape(c, body, (p) {
      p.moveTo(64, 58);
      p.lineTo(34, 54);
      p.quadraticBezierTo(22, 54, 22, 62);
      p.lineTo(40, 68);
      p.lineTo(62, 72);
    });
    _underbone(c, body);
    c.box(66, 61, 22, 11, cream, 4);
    c.oval(77, 66.5, 2.4, 2.4, body);
    c.box(19, 57, 5, 6, _red, 2);
    _plate(c, 19, 64);
    // Carrier.
    c.stroke(24, 48, 56, 48, _chrome, 1.6);
    c.stroke(26, 48, 28, 55, _chrome, 1.4);
    c.stroke(40, 48, 40, 54, _chrome, 1.4);
    c.stroke(24, 48, 22, 51, _chrome, 1.4);
    // Saddle.
    _shape(c, const Color(0xFF7A1F1F), (p) {
      p.moveTo(56, 57);
      p.quadraticBezierTo(56, 45, 68, 45);
      p.lineTo(104, 46);
      p.quadraticBezierTo(112, 47, 110, 55);
      p.quadraticBezierTo(84, 61, 56, 57);
    });
    c.stroke(60, 54.5, 108, 53, cream, 0.9);
    // Leg shield.
    _shape(c, cream, (p) {
      p.moveTo(128, 38);
      p.quadraticBezierTo(140, 40, 138, 52);
      p.quadraticBezierTo(134, 76, 128, 90);
      p.lineTo(118, 92);
      p.quadraticBezierTo(124, 70, 120, 50);
      p.quadraticBezierTo(120, 40, 128, 38);
    });
    c.stroke(123, 48, 126, 86, shade(cream, -0.14), 1);
    // Headlamp nacelle.
    c.box(126, 26, 24, 15, body, 7);
    c.oval(149, 33.5, 7, 7.4, _chrome);
    c.oval(150, 33.5, 5, 5.6, _lens);
    c.box(140, 41, 5, 3, const Color(0xFFF0A63A), 1);
    _bars(c, 134, 27);
  }

  static void _wave(Canvas c) {
    const body = Color(0xFFC4262B);
    const trim = Color(0xFFF0C24B);
    c.stroke(_fx, _ay, 140, 40, _chromeDark, 4);
    _wheel(c, _rx);
    _wheel(c, _fx);
    // Sporty short mudguard up front, plastic hugger behind.
    _guard(c, _fx, 205, 120, body);
    _guard(c, _rx, 200, 80, _black, width: 4);
    c.stroke(_fx - 2, _ay - 4, 142, 48, _black, 5);
    c.stroke(_rx, _ay + 1, 84, _ay - 1, _black, 9);
    _flatEngine(c, cases: const Color(0xFF3A3D42));
    // Black can with a chrome heat shield, kicked up.
    c.stroke(100, 98, 74, 100, _chromeDark, 2.4);
    c.stroke(76, 100, 26, 90, _black, 8);
    c.stroke(62, 96, 34, 90.5, _chrome, 3.4);
    _shock(c, 56, 62, 49, 88);
    // Pointed tail rising to the lamp.
    _shape(c, body, (p) {
      p.moveTo(66, 58);
      p.lineTo(16, 40);
      p.lineTo(14, 45);
      p.lineTo(40, 64);
      p.lineTo(64, 72);
    });
    c.poly([14, 40, 22, 42, 20, 47, 13, 45], _red);
    c.poly([62, 62, 28, 49, 30, 53, 60, 67], trim);
    c.poly([58, 68, 40, 61, 42, 64, 58, 71], const Color(0xFFF2EFE6));
    _underbone(c, body);
    c.poly([118, 62, 98, 76, 102, 78, 121, 66], trim);
    _plate(c, 24, 60);
    // Grab rail.
    c.stroke(22, 40, 44, 44, _chrome, 1.6);
    c.stroke(44, 44, 46, 50, _chrome, 1.4);
    // Stepped seat.
    _shape(c, _black, (p) {
      p.moveTo(44, 52);
      p.quadraticBezierTo(46, 42, 58, 43);
      p.lineTo(78, 47);
      p.lineTo(108, 47);
      p.quadraticBezierTo(114, 48, 112, 55);
      p.quadraticBezierTo(84, 61, 62, 58);
    });
    // Slim leg shield with a dark inner.
    _shape(c, body, (p) {
      p.moveTo(130, 40);
      p.quadraticBezierTo(142, 44, 138, 58);
      p.lineTo(126, 90);
      p.lineTo(117, 92);
      p.quadraticBezierTo(126, 68, 122, 50);
      p.quadraticBezierTo(122, 42, 130, 40);
    });
    c.poly([124, 52, 128, 52, 122, 88, 119, 89], _black);
    c.poly([134, 50, 138, 54, 130, 78, 128, 74], trim);
    // Angular cowl with the lamp let into it.
    _shape(c, body, (p) {
      p.moveTo(124, 30);
      p.lineTo(146, 24);
      p.lineTo(156, 33);
      p.lineTo(148, 43);
      p.lineTo(128, 42);
    });
    c.poly([144, 28, 154, 33, 148, 40, 141, 38], _lens);
    c.poly([130, 34, 138, 33, 138, 37, 131, 38], const Color(0xFFF0A63A));
    _bars(c, 134, 28);
  }

  static void _dream(Canvas c) {
    const body = Color(0xFF6B1F2A);
    const gold = Color(0xFFD9C7A0);
    c.stroke(_fx, _ay, 139, 40, _chromeDark, 4);
    _wheel(c, _rx);
    _wheel(c, _fx);
    _guard(c, _fx, 192, 156, body);
    _guard(c, _rx, 176, 112, body);
    c.stroke(_fx - 2, _ay - 2, 141, 46, body, 6.4);
    c.stroke(_rx, _ay + 1, 84, _ay - 1, _black, 10);
    c.stroke(_rx + 2, _ay - 2.4, 82, _ay - 4.4, _chromeDark, 0.9);
    _flatEngine(c);
    // Long bright silencer, level with the ground.
    c.stroke(100, 98, 76, 102, _chromeDark, 2.6);
    c.stroke(78, 102, 22, 102, _chrome, 7.6);
    c.stroke(74, 100.4, 26, 100.4, const Color(0xFFEFF2F4), 1.4);
    c.oval(21, 102, 1.8, 2.6, _black);
    _shock(c, 54, 62, 49, 88);
    // Big square tail.
    _shape(c, body, (p) {
      p.moveTo(66, 56);
      p.lineTo(22, 52);
      p.quadraticBezierTo(16, 53, 16, 60);
      p.lineTo(18, 66);
      p.lineTo(44, 70);
      p.lineTo(64, 73);
    });
    c.box(13, 54, 6, 11, _red, 1.5);
    c.box(13, 61, 6, 4, const Color(0xFFF0A63A), 1);
    c.stroke(24, 60, 62, 64, _chrome, 1.6);
    c.stroke(24, 62.4, 62, 66.4, gold, 0.9);
    _underbone(c, body);
    c.box(66, 62, 20, 9, shade(body, -0.25), 3);
    _plate(c, 17, 67);
    // Chrome carrier with a grab loop.
    c.stroke(18, 46, 54, 46, _chrome, 2);
    c.stroke(18, 46, 16, 51, _chrome, 1.6);
    c.stroke(30, 46, 32, 52, _chrome, 1.4);
    c.stroke(46, 46, 46, 52, _chrome, 1.4);
    // Long flat dual seat.
    _shape(c, _black, (p) {
      p.moveTo(50, 56);
      p.quadraticBezierTo(50, 45, 60, 45);
      p.lineTo(106, 46);
      p.quadraticBezierTo(114, 47, 112, 55);
      p.quadraticBezierTo(82, 60, 50, 56);
    });
    c.stroke(54, 54, 110, 53, const Color(0xFF55585C), 0.8);
    // Broad leg shield.
    _shape(c, body, (p) {
      p.moveTo(128, 37);
      p.quadraticBezierTo(142, 40, 140, 54);
      p.quadraticBezierTo(136, 78, 130, 91);
      p.lineTo(117, 93);
      p.quadraticBezierTo(124, 70, 120, 50);
      p.quadraticBezierTo(120, 39, 128, 37);
    });
    c.stroke(123, 48, 125, 88, shade(body, -0.3), 1);
    c.stroke(136, 50, 130, 84, gold, 0.9);
    // Square lamp in a square nacelle.
    c.box(125, 25, 27, 17, body, 4);
    c.box(144, 28, 9, 11, _chrome, 1.5);
    c.box(146, 29.5, 6, 8, _lens, 1);
    c.box(138, 42, 6, 3.4, const Color(0xFFF0A63A), 1);
    _bars(c, 134, 26);
  }

  static void _x67(Canvas c) {
    // A proper little motorcycle: tank between the knees, forks on show.
    _wheel(c, _rx);
    _wheel(c, _fx);
    _guard(c, _fx, 205, 130, _chrome, width: 3.6);
    _guard(c, _rx, 172, 120, _chrome, width: 3.6);
    // Telescopic fork: bright slider below, black shroud above.
    c.stroke(_fx, _ay, 141, 36, _chrome, 4.4);
    c.stroke(149.5, 66, 141.5, 38, _black, 5.4);
    // Stay holding the rear guard.
    c.stroke(_rx, _ay, 30, 70, _chromeDark, 1);
    // Bare chain, top and bottom runs.
    c.stroke(_rx, _ay - 4, 86, _ay - 6, const Color(0xFF55585C), 1.3);
    c.stroke(_rx, _ay + 4, 86, _ay + 2, const Color(0xFF55585C), 1.3);
    c.oval(_rx, _ay, 9, 9, _chromeDark);
    c.oval(_rx, _ay, 7.4, 7.4, const Color(0xFFE9E2CE));
    // Pressed-steel spine from the headstock to the rear.
    _shape(c, const Color(0xFF2C2D31), (p) {
      p.moveTo(140, 44);
      p.lineTo(104, 62);
      p.lineTo(58, 60);
      p.lineTo(52, 66);
      p.lineTo(84, 74);
      p.lineTo(108, 76);
      p.lineTo(142, 52);
    });
    _flatEngine(c);
    c.box(84, 70, 16, 11, _engine, 3);
    _shock(c, 60, 60, 50, 88, bare: true);
    // Upswept pipe with a slotted heat shield.
    c.stroke(110, 93, 76, 93, _chrome, 3.4);
    c.stroke(76, 93, 20, 70, _chrome, 7.4);
    c.stroke(64, 87.4, 32, 74.4, _black, 4.4);
    for (var k = 0; k < 6; k++) {
      final x = 60.0 - k * 5, y = 85.8 - k * 2.03;
      c.stroke(x, y - 1, x - 1.6, y + 0.6, _chromeDark, 0.9);
    }
    c.oval(19, 69.6, 1.8, 2.6, _black);
    // Long tank with chrome flanks and a knee pad.
    _shape(c, _black, (p) {
      p.moveTo(92, 52);
      p.quadraticBezierTo(94, 38, 116, 37);
      p.quadraticBezierTo(138, 37, 138, 46);
      p.quadraticBezierTo(136, 56, 114, 58);
      p.quadraticBezierTo(96, 60, 92, 52);
    });
    _shape(c, _chrome, (p) {
      p.moveTo(110, 42);
      p.quadraticBezierTo(132, 40, 134, 46);
      p.quadraticBezierTo(132, 53, 112, 54);
      p.quadraticBezierTo(104, 48, 110, 42);
    });
    c.box(112, 44.5, 12, 6.4, _black, 3);
    c.oval(116, 37.6, 3, 1.6, _chrome);
    // Flat seat with a little hump.
    _shape(c, _black, (p) {
      p.moveTo(40, 54);
      p.quadraticBezierTo(38, 42, 48, 44);
      p.lineTo(92, 47);
      p.lineTo(94, 55);
      p.quadraticBezierTo(66, 60, 40, 54);
    });
    c.stroke(44, 53, 92, 53.6, _chromeDark, 0.9);
    // Round tail lamp on the guard, plate beneath.
    c.box(20, 58, 7, 7, _chromeDark, 3);
    c.oval(21.6, 61.5, 3, 3, _red);
    _plate(c, 20, 68);
    // Chrome headlamp and a pair of clocks.
    c.oval(148, 41, 9.4, 9.8, _chrome);
    c.oval(150.6, 41, 6, 7.6, _lens);
    c.oval(139, 30, 3.6, 3.2, _chromeDark);
    c.stroke(142, 50, 148, 52, const Color(0xFFF0A63A), 2.6);
    _bars(c, 139, 33, low: true);
  }
}

/// The garage picture of [bike], sized by its parent.
class BikeSideView extends StatelessWidget {
  const BikeSideView(this.bike, {super.key});
  final BikeId bike;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: BikeSidePainter(bike),
    size: Size.infinite,
  );
}
