import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../core/bikes.dart';
import '../core/world.dart';
import 'draw.dart';

const _skin = Color(0xFFE0B48C);
const _tyre = Color(0xFF1B1B1B);
const _chrome = Color(0xFFC9CED2);
const _glass = Color(0xFF9FC4D0);
const _hatStraw = Color(0xFFEADBA5);
const _trouser = Color(0xFF2E3440);

const riderShirts = [
  Color(0xFFF4F1E8), Color(0xFFD9534F), Color(0xFF3B6FB5), Color(0xFFF0C24B),
  Color(0xFF5BA36B), Color(0xFF8E5BA3),
];

class _Look {
  const _Look(this.body, this.trim, {this.shield = true, this.boxy = false,
    this.rack = false, this.chromeFender = false, this.highPipe = false,
    this.roundLight = true});
  final Color body;
  final Color trim;
  final bool shield;
  final bool boxy;
  final bool rack;
  final bool chromeFender;
  final bool highPipe;
  final bool roundLight;
}

const Map<BikeId, _Look> _looks = {
  BikeId.cub: _Look(Color(0xFF2F6FB0), Color(0xFFF2EFE6), rack: true),
  BikeId.wave: _Look(Color(0xFFC4262B), Color(0xFFF0C24B), roundLight: false),
  BikeId.dream: _Look(Color(0xFF6B1F2A), Color(0xFFD9C7A0), boxy: true,
      rack: true, roundLight: false),
  BikeId.x67: _Look(Color(0xFF1E1E22), Color(0xFFC9CED2), shield: false,
      chromeFender: true, highPipe: true),
};

/// A bike and rider, 60 x 100 design units, seen from behind or head-on.
Sprite buildRider(BikeId bike, int color, {bool front = false}) => makeSprite(
  60, 100, 1.35, 150,
  (c) => front ? _riderFront(c, bike, color) : _riderRear(c, bike, color),
);

void _headgear(Canvas c, int kind, double cx, double cy, {bool front = false}) {
  // cy is the centre of the head.
  switch (kind % 6) {
    case 0: // Pith helmet.
      c.oval(cx, cy - 1, 10.5, 3.2, const Color(0xFF55693F));
      final dome = Path()
        ..addArc(Rect.fromCenter(center: Offset(cx, cy - 1), width: 16,
            height: 17), math.pi, math.pi);
      c.drawPath(dome, Paint()..color = const Color(0xFF6B8050));
    case 1: // Floppy jungle hat.
      c.oval(cx, cy - 2, 11, 3.6, const Color(0xFF7B7A52));
      c.box(cx - 6.5, cy - 9, 13, 8, const Color(0xFF8B8A5E), 3);
    case 2: // Bare head.
      c.oval(cx, cy - 2.5, 7.4, 6, const Color(0xFF1E1A18));
      if (front) c.oval(cx, cy + 1, 6.4, 5.6, _skin);
    case 3: // Peaked cap.
      c.box(cx - 7, cy - 8.5, 14, 8, const Color(0xFF2F4A7A), 4);
      if (front) c.box(cx - 8, cy - 2.5, 16, 2.4, const Color(0xFF233A60), 1);
    case 4: // Old bowl helmet.
      final dome = Path()
        ..addArc(Rect.fromCenter(center: Offset(cx, cy), width: 17, height: 19),
            math.pi, math.pi);
      c.drawPath(dome, Paint()..color = const Color(0xFFEDEBE2));
      c.box(cx - 8.5, cy - 0.5, 17, 1.6, const Color(0xFFB3261E));
    case 5: // Conical hat.
      c.poly([cx - 14, cy, cx + 14, cy, cx, cy - 12], _hatStraw);
      c.poly([cx - 14, cy, cx, cy, cx, cy - 12], shade(_hatStraw, -0.12));
  }
}

void _riderRear(Canvas c, BikeId bike, int color) {
  final look = _looks[bike]!;
  final shirt = riderShirts[color % riderShirts.length];

  // Handlebars and mirrors sit furthest away.
  c.stroke(9, 41, 51, 41, const Color(0xFF3A3A3A), 2);
  for (final x in [9.0, 51.0]) {
    c.stroke(x, 41, x + (x < 30 ? -1.5 : 1.5), 33, const Color(0xFF3A3A3A), 1);
    c.oval(x + (x < 30 ? -2 : 2), 31.5, 3, 2.4, _chrome);
  }
  if (look.shield) {
    // Leg shield wings peeking out either side.
    c.box(10, 46, 9, 28, look.shield && bike == BikeId.cub ? look.trim : look.body, 3);
    c.box(41, 46, 9, 28, look.shield && bike == BikeId.cub ? look.trim : look.body, 3);
  }

  // Rear wheel and suspension.
  c.box(25, 68, 10, 32, _tyre, 4);
  c.box(28.5, 70, 3, 28, const Color(0xFF2E2E2E), 1.5);
  for (final x in [21.0, 37.0]) {
    c.box(x, 58, 2.4, 22, look.chromeFender ? _chrome : const Color(0xFF55585C), 1);
    if (look.chromeFender) {
      for (var y = 60.0; y < 78; y += 3) {
        c.stroke(x, y, x + 2.4, y + 1, const Color(0xFF7F868B), 0.6);
      }
    }
  }
  // Exhaust.
  if (look.highPipe) {
    c.poly([38, 80, 46, 62, 49, 63, 42, 82], _chrome);
    c.oval(47.5, 62, 2.2, 2.2, const Color(0xFF2A2A2A));
  } else {
    c.box(38, 76, 7, 9, bike == BikeId.wave ? const Color(0xFF2A2A2A) : _chrome, 3);
    c.oval(41.5, 80.5, 1.8, 1.8, const Color(0xFF111111));
  }

  // Tail section.
  final tailW = look.boxy ? 26.0 : (bike == BikeId.x67 ? 14.0 : 20.0);
  final tx = 30 - tailW / 2;
  c.box(tx, 53, tailW, 15, look.body, look.boxy ? 2 : 5);
  if (bike == BikeId.wave) {
    c.poly([tx, 60, tx + tailW, 56, tx + tailW, 59, tx, 63], look.trim);
  }
  if (bike == BikeId.dream) {
    c.box(tx, 60, tailW, 2, look.trim);
  }
  c.box(24, 64, 12, 8, look.chromeFender ? _chrome : shade(look.body, -0.25), 2);
  // Tail light.
  if (look.roundLight) {
    c.oval(30, 60, 3.2, 3.2, const Color(0xFFD6312B));
    c.oval(29.3, 59.2, 1.1, 1.1, const Color(0xFFFF8A80));
  } else {
    c.box(30 - (look.boxy ? 9 : 5), 57.5, look.boxy ? 18 : 10, 4.5,
        const Color(0xFFD6312B), 1.2);
    if (look.boxy) {
      c.box(21, 57.5, 3.5, 4.5, const Color(0xFFF0A63A), 1);
      c.box(35.5, 57.5, 3.5, 4.5, const Color(0xFFF0A63A), 1);
    }
  }
  c.box(24.5, 66, 11, 6, const Color(0xFFF4F4F0), 0.8);
  c.stroke(26, 68, 34, 68, const Color(0xFF333333), 0.7);
  c.stroke(26, 70, 34, 70, const Color(0xFF333333), 0.7);
  if (look.rack) {
    c.stroke(20, 52, 40, 52, _chrome, 1.3);
    c.stroke(20, 52, 20, 56, _chrome, 1.3);
    c.stroke(40, 52, 40, 56, _chrome, 1.3);
  }

  // Legs and sandals on the pegs.
  c.poly([22, 50, 30, 50, 22, 74, 13, 72], _trouser);
  c.poly([30, 50, 38, 50, 47, 72, 38, 74], _trouser);
  c.box(11, 71, 10, 4.5, const Color(0xFF6B4A2F), 2);
  c.box(39, 71, 10, 4.5, const Color(0xFF6B4A2F), 2);
  // Seat.
  c.box(19, 48, 22, 7, const Color(0xFF1C1C1C), 3);

  // Torso, arms, head.
  final lean = bike == BikeId.x67 ? 3.0 : 0.0;
  c.poly([19, 24 + lean, 41, 24 + lean, 40, 52, 20, 52], shirt);
  c.poly([19, 24 + lean, 23, 24 + lean, 23, 52, 20, 52], shade(shirt, -0.12));
  c.stroke(20.5, 28 + lean, 10.5, 40, shirt, 5.2);
  c.stroke(39.5, 28 + lean, 49.5, 40, shirt, 5.2);
  c.oval(10, 41, 2.6, 2.6, _skin);
  c.oval(50, 41, 2.6, 2.6, _skin);
  c.box(27, 19 + lean, 6, 6, _skin);
  c.oval(30, 14 + lean, 6.6, 7.2, _skin);
  c.oval(30, 12.5 + lean, 6.8, 6, const Color(0xFF1E1A18));
  _headgear(c, color, 30, 12 + lean);
}

void _riderFront(Canvas c, BikeId bike, int color) {
  final look = _looks[bike]!;
  final shirt = riderShirts[color % riderShirts.length];

  // Rider first; the bike's nose covers the lap.
  c.poly([19, 24, 41, 24, 40, 54, 20, 54], shirt);
  c.poly([27, 24, 33, 24, 30, 31], _skin);
  c.box(27, 19, 6, 6, _skin);
  c.oval(30, 14, 6.6, 7.2, _skin);
  c.oval(27.6, 13.5, 0.9, 1.1, const Color(0xFF1E1A18));
  c.oval(32.4, 13.5, 0.9, 1.1, const Color(0xFF1E1A18));
  _headgear(c, color, 30, 11, front: true);
  // Knees out wide.
  c.poly([20, 50, 26, 50, 20, 76, 12, 74], _trouser);
  c.poly([34, 50, 40, 50, 48, 74, 40, 76], _trouser);

  // Front wheel, forks, mudguard.
  c.box(26, 70, 8, 30, _tyre, 3.5);
  c.box(24, 52, 2.2, 34, _chrome);
  c.box(33.8, 52, 2.2, 34, _chrome);
  c.box(24.5, 66, 11, 8, look.chromeFender ? _chrome : look.body, 3);
  if (look.shield) {
    final col = bike == BikeId.cub ? look.trim : look.body;
    c.poly([13, 48, 47, 48, 44, 76, 34, 80, 26, 80, 16, 76], col);
    c.box(27, 50, 6, 28, shade(col, -0.15));
  } else {
    // Naked bike: tank shoulders and the upright engine.
    c.box(22, 46, 16, 12, look.body, 4);
    c.box(25, 58, 10, 10, const Color(0xFF8D9499), 1.5);
  }
  // Headlight nacelle.
  c.box(22, 36, 16, 13, look.shield ? look.body : _chrome, look.roundLight ? 6 : 2);
  if (look.roundLight) {
    c.oval(30, 42.5, 5, 5, const Color(0xFFFFF3C4));
    c.oval(30, 42.5, 3, 3, const Color(0xFFFFFBE8));
  } else {
    c.box(24.5, 39, 11, 7, const Color(0xFFFFF3C4), 1.5);
  }
  // Bars, mirrors, hands.
  c.stroke(9, 40, 51, 40, const Color(0xFF3A3A3A), 2);
  for (final x in [9.0, 51.0]) {
    c.stroke(x, 40, x + (x < 30 ? -1.5 : 1.5), 32, const Color(0xFF3A3A3A), 1);
    c.oval(x + (x < 30 ? -2 : 2), 30.5, 3, 2.4, _chrome);
  }
  c.stroke(20.5, 28, 10.5, 39, shirt, 5.2);
  c.stroke(39.5, 28, 49.5, 39, shirt, 5.2);
  c.oval(10, 40, 2.6, 2.6, _skin);
  c.oval(50, 40, 2.6, 2.6, _skin);
}

const _paint6 = [
  Color(0xFFE9DFC6), Color(0xFF7FA8C9), Color(0xFF3F6B55), Color(0xFFB3261E),
  Color(0xFF2E3440), Color(0xFFD99A3A),
];

Sprite buildVehicle(VehicleKind kind, int v, bool front) {
  switch (kind) {
    case VehicleKind.bicycle:
      return makeSprite(50, 100, 1.15, 110, (c) => _bicycle(c, v, front));
    case VehicleKind.cyclo:
      return makeSprite(80, 100, 1.6, 144, (c) => _cyclo(c, v, front));
    case VehicleKind.moto:
      return buildRider(BikeId.values[v % 4], 1 + v % 5, front: front);
    case VehicleKind.lam:
      return makeSprite(80, 96, 1.75, 160, (c) => _lam(c, v, front));
    case VehicleKind.car:
      return makeSprite(100, 74, 2.0, 176, (c) => _car(c, v, front));
    case VehicleKind.truck:
      return makeSprite(100, 126, 2.05, 192, (c) => _truck(c, v, front));
    case VehicleKind.bus:
      return makeSprite(100, 142, 2.1, 192, (c) => _bus(c, v, front));
    case VehicleKind.oxcart:
      return makeSprite(90, 96, 1.9, 160, (c) => _oxcart(c, v, front));
  }
}

void _bicycle(Canvas c, int v, bool front) {
  final aoDai = v % 3 == 0;
  final shirt = aoDai
      ? const Color(0xFFF7F5EE)
      : (v % 3 == 1 ? const Color(0xFF7A5540) : const Color(0xFF6C8FB8));
  c.box(23.5, 60, 3, 40, _tyre, 1.5);
  c.box(22.5, 58, 5, 16, const Color(0xFF8D9499), 2);
  if (!front && v.isOdd) {
    // Something strapped on the rack.
    c.box(13, 50, 24, 14, const Color(0xFFB98A4A), 2);
    for (var x = 15.0; x < 36; x += 4) {
      c.stroke(x, 51, x, 63, const Color(0xFF8A6432), 0.7);
    }
  }
  if (front) {
    // Basket up front.
    c.box(15, 50, 20, 12, const Color(0xFFB98A4A), 2);
    c.oval(21, 49, 3, 3, const Color(0xFFD9534F));
    c.oval(28, 48, 3.4, 3.4, const Color(0xFFF0C24B));
  }
  c.stroke(10, 44, 40, 44, const Color(0xFF55585C), 1.6);
  // Legs.
  c.poly([19, 50, 25, 50, 21, 78, 15, 77], aoDai ? shirt : _trouser);
  c.poly([25, 50, 31, 50, 35, 70, 29, 71], aoDai ? shirt : _trouser);
  c.poly([17, 26, 33, 26, 34, 54, 16, 54], shirt);
  if (aoDai && !front) {
    // The back flap of the dress, pinned to the saddle.
    c.poly([18, 50, 32, 50, 36, 74, 26, 70], shade(shirt, -0.06));
    c.stroke(25, 22, 25, 40, const Color(0xFF1E1A18), 2.4);
  }
  c.stroke(18, 30, 11, 44, shirt, 4.2);
  c.stroke(32, 30, 39, 44, shirt, 4.2);
  c.oval(25, 18, 5.6, 6.2, _skin);
  if (front) {
    c.oval(23, 18, 0.8, 1, const Color(0xFF1E1A18));
    c.oval(27, 18, 0.8, 1, const Color(0xFF1E1A18));
  } else {
    c.oval(25, 17, 5.8, 5.4, const Color(0xFF1E1A18));
  }
  if (v % 3 == 2) {
    _headgear(c, 0, 25, 16, front: front);
  } else {
    c.poly([7, 17, 43, 17, 25, 3], _hatStraw);
    c.poly([7, 17, 25, 17, 25, 3], shade(_hatStraw, -0.12));
  }
}

void _cyclo(Canvas c, int v, bool front) {
  final tub = [const Color(0xFFB3261E), const Color(0xFF1F4E8C),
    const Color(0xFF1E6B45)][v % 3];
  void driver(double y) {
    c.poly([30, y + 20, 50, y + 20, 49, y + 46, 31, y + 46],
        const Color(0xFF7A6A52));
    c.oval(40, y + 13, 6, 6.6, _skin);
    if (!front) c.oval(40, y + 12, 6.2, 5.6, const Color(0xFF1E1A18));
    _headgear(c, 1, 40, y + 11, front: front);
  }

  if (front) {
    driver(-4);
    // Hood up over the passenger seat.
    final hood = Path()
      ..moveTo(12, 56)
      ..quadraticBezierTo(12, 20, 40, 20)
      ..quadraticBezierTo(68, 20, 68, 56)
      ..close();
    c.drawPath(hood, Paint()..color = const Color(0xFF3C4A3A));
    c.box(18, 34, 44, 24, const Color(0xFF242A24), 4);
    if (v.isEven) {
      // A fare, half in shadow.
      c.box(32, 42, 16, 16, const Color(0xFFF4F1E8), 3);
      c.oval(40, 38, 5, 5.4, _skin);
    }
    c.box(8, 54, 64, 24, tub, 5);
    c.box(8, 54, 64, 5, _chrome, 2);
    c.box(20, 78, 40, 5, const Color(0xFF55585C), 1);
    c.box(7, 62, 4, 38, _tyre, 2);
    c.box(69, 62, 4, 38, _tyre, 2);
    c.box(5, 58, 8, 8, _chrome, 3);
    c.box(67, 58, 8, 8, _chrome, 3);
  } else {
    c.box(7, 62, 4, 38, _tyre, 2);
    c.box(69, 62, 4, 38, _tyre, 2);
    c.box(10, 50, 60, 28, tub, 5);
    // Folded hood behind the seat back.
    c.box(12, 42, 56, 12, const Color(0xFF3C4A3A), 5);
    c.box(10, 50, 60, 4, _chrome, 2);
    c.box(38.5, 62, 3, 38, _tyre, 1.5);
    c.box(37, 58, 6, 14, _chrome, 2);
    c.poly([33, 52, 40, 52, 36, 80, 30, 79], _trouser);
    c.poly([40, 52, 47, 52, 50, 72, 44, 73], _trouser);
    driver(6);
    c.stroke(31, 30, 24, 46, const Color(0xFF7A6A52), 4.4);
    c.stroke(49, 30, 56, 46, const Color(0xFF7A6A52), 4.4);
  }
}

void _lam(Canvas c, int v, bool front) {
  final body = [const Color(0xFF2F6FB0), const Color(0xFF3F8B6A),
    const Color(0xFFD99A3A)][v % 3];
  const canvasTop = Color(0xFFE6DFC8);
  if (front) {
    c.box(6, 36, 68, 40, shade(body, -0.25), 3);
    c.box(4, 10, 72, 12, canvasTop, 5);
    c.box(10, 80, 9, 16, _tyre, 3);
    c.box(61, 80, 9, 16, _tyre, 3);
    c.box(18, 16, 44, 56, body, 12);
    c.box(23, 22, 34, 18, _glass, 4);
    c.box(39.2, 22, 1.6, 18, shade(body, -0.2));
    c.oval(32, 36, 4.4, 5, const Color(0xFF2A2420));
    c.box(18, 46, 44, 3, const Color(0xFFF0E6C8));
    c.oval(40, 56, 5.5, 5.5, const Color(0xFFFFF3C4));
    c.oval(40, 56, 3.2, 3.2, const Color(0xFFFFFBE8));
    c.box(36, 72, 8, 24, _tyre, 3.5);
    c.box(33, 68, 14, 8, shade(body, -0.15), 4);
  } else {
    c.box(10, 78, 10, 18, _tyre, 3);
    c.box(60, 78, 10, 18, _tyre, 3);
    c.box(4, 8, 72, 14, canvasTop, 6);
    c.box(8, 20, 64, 58, body, 3);
    c.box(13, 22, 54, 34, const Color(0xFF26221E), 2);
    // Passengers knee to knee on the two benches.
    const shirts = [Color(0xFFF4F1E8), Color(0xFF7A5540), Color(0xFFD9534F),
      Color(0xFF6C8FB8)];
    for (var k = 0; k < 4; k++) {
      final x = 20 + k * 13.5;
      c.box(x - 5, 38, 10, 18, shirts[(k + v) % 4], 3);
      c.oval(x, 33, 4, 4.4, _skin);
      if (k.isEven) {
        c.poly([x - 8, 32, x + 8, 32, x, 25], _hatStraw);
      } else {
        c.oval(x, 31.5, 4.2, 3.6, const Color(0xFF1E1A18));
      }
    }
    c.box(8, 56, 64, 4, const Color(0xFFF0E6C8));
    c.box(11, 62, 7, 5, const Color(0xFFD6312B), 1.5);
    c.box(62, 62, 7, 5, const Color(0xFFD6312B), 1.5);
    c.box(30, 63, 20, 8, const Color(0xFFF4F4F0), 1);
    c.stroke(33, 67, 47, 67, const Color(0xFF333333), 0.9);
    c.box(6, 76, 68, 4, const Color(0xFF55585C), 1);
  }
}

void _car(Canvas c, int v, bool front) {
  final body = _paint6[v % 6];
  c.box(9, 56, 15, 18, _tyre, 4);
  c.box(76, 56, 15, 18, _tyre, 4);
  c.poly([18, 28, 27, 5, 73, 5, 82, 28], body);
  c.poly([23, 26, 30, 9, 70, 9, 77, 26], _glass);
  c.box(5, 26, 90, 34, body, 7);
  c.box(5, 26, 90, 5, shade(body, 0.18), 3);
  if (front) {
    c.oval(38, 21, 5, 5.4, const Color(0xFF2A2420));
    c.box(30, 38, 40, 12, const Color(0xFF2B2B2B), 2);
    for (var x = 33.0; x < 70; x += 4) {
      c.stroke(x, 39, x, 49, _chrome, 0.9);
    }
    c.oval(18, 43, 6.5, 6.5, _chrome);
    c.oval(82, 43, 6.5, 6.5, _chrome);
    c.oval(18, 43, 4.8, 4.8, const Color(0xFFFFF3C4));
    c.oval(82, 43, 4.8, 4.8, const Color(0xFFFFF3C4));
  } else {
    c.box(8, 36, 14, 7, const Color(0xFFD6312B), 2);
    c.box(78, 36, 14, 7, const Color(0xFFD6312B), 2);
    c.box(8, 44, 14, 3, const Color(0xFFF0A63A), 1);
    c.box(78, 44, 14, 3, const Color(0xFFF0A63A), 1);
    c.stroke(30, 34, 70, 34, shade(body, -0.25), 0.9);
  }
  c.box(3, 54, 94, 6, _chrome, 3);
  c.box(38, 44, 24, 9, const Color(0xFFF4F4F0), 1);
  c.stroke(42, 48.5, 58, 48.5, const Color(0xFF333333), 1);
}

void _truck(Canvas c, int v, bool front) {
  final cab = [const Color(0xFF55693F), const Color(0xFF2F5F8C),
    const Color(0xFF7A4A2E)][v % 3];
  const tarp = Color(0xFF8B8563);
  if (front) {
    c.box(4, 4, 92, 40, tarp, 6);
    c.box(8, 96, 20, 30, _tyre, 5);
    c.box(72, 96, 20, 30, _tyre, 5);
    c.box(9, 26, 82, 72, cab, 8);
    c.box(15, 32, 33, 24, _glass, 3);
    c.box(52, 32, 33, 24, _glass, 3);
    c.oval(64, 48, 6, 6.6, const Color(0xFF2A2420));
    c.box(28, 62, 44, 26, const Color(0xFF2B2B2B), 3);
    for (var y = 66.0; y < 88; y += 5) {
      c.stroke(31, y, 69, y, shade(cab, 0.3), 1.2);
    }
    c.oval(18, 76, 7, 7, _chrome);
    c.oval(82, 76, 7, 7, _chrome);
    c.oval(18, 76, 5, 5, const Color(0xFFFFF3C4));
    c.oval(82, 76, 5, 5, const Color(0xFFFFF3C4));
    c.box(4, 94, 92, 8, const Color(0xFF3A3A3A), 2);
  } else {
    c.box(7, 92, 26, 34, _tyre, 5);
    c.box(67, 92, 26, 34, _tyre, 5);
    c.box(40, 96, 20, 10, const Color(0xFF3A3A3A), 2);
    if (v.isEven) {
      // Canvas tilt roped down.
      c.box(4, 4, 92, 64, tarp, 8);
      for (final x in [24.0, 50.0, 76.0]) {
        c.stroke(x, 6, x, 68, shade(tarp, -0.25), 1);
      }
      c.poly([30, 30, 70, 30, 66, 68, 34, 68], shade(tarp, -0.18));
    } else {
      // Open bed stacked with rice sacks.
      const sack = Color(0xFFD9CBA3);
      for (var row = 0; row < 3; row++) {
        for (var k = 0; k < 4 - row; k++) {
          c.box(10 + row * 10 + k * 20.0, 44 - row * 14.0, 19, 13,
              (row + k).isEven ? sack : shade(sack, -0.1), 4);
        }
      }
    }
    c.box(4, 58, 92, 30, cab, 2);
    for (final y in [66.0, 74.0, 82.0]) {
      c.stroke(6, y, 94, y, shade(cab, -0.25), 0.9);
    }
    c.box(9, 88, 12, 6, const Color(0xFFD6312B), 1.5);
    c.box(79, 88, 12, 6, const Color(0xFFD6312B), 1.5);
    c.box(38, 86, 24, 9, const Color(0xFFF4F4F0), 1);
    c.stroke(42, 90.5, 58, 90.5, const Color(0xFF333333), 1);
    c.box(8, 96, 22, 16, const Color(0xFF151515), 1);
    c.box(70, 96, 22, 16, const Color(0xFF151515), 1);
  }
}

void _bus(Canvas c, int v, bool front) {
  const places = ['SÀI GÒN', 'MỸ THO', 'ĐÀ LẠT', 'HÀ NỘI', 'HUẾ', 'CẦN THƠ'];
  final band = [const Color(0xFFB3261E), const Color(0xFF1F4E8C),
    const Color(0xFF1E6B45)][v % 3];
  const cream = Color(0xFFEDE3C6);
  c.box(10, 120, 19, 22, _tyre, 5);
  c.box(71, 120, 19, 22, _tyre, 5);
  // Everything that would not fit inside goes on the roof.
  c.stroke(8, 12, 92, 12, _chrome, 1.4);
  const load = [Color(0xFFB98A4A), Color(0xFF7A8FA6), Color(0xFFD9CBA3),
    Color(0xFF8B5E3C), Color(0xFF6B8F5A)];
  for (var k = 0; k < 5; k++) {
    c.box(11 + k * 16.0, k.isEven ? 3 : 7, 14, k.isEven ? 19 : 15,
        load[(k + v) % 5], k.isEven ? 3 : 6);
  }
  c.box(5, 20, 90, 104, cream, 8);
  c.box(5, 66, 90, 16, band);
  c.box(5, 84, 90, 3, shade(band, -0.2));
  if (front) {
    c.box(20, 24, 60, 11, const Color(0xFFF7F5EE), 2);
    c.label(places[v % 6], 50, 29.8, 7.5, const Color(0xFF7A1A12), maxW: 54);
    c.box(11, 38, 37, 26, _glass, 3);
    c.box(52, 38, 37, 26, _glass, 3);
    c.oval(68, 56, 6, 6.6, const Color(0xFF2A2420));
    c.box(30, 90, 40, 18, const Color(0xFF2B2B2B), 2);
    for (var y = 93.0; y < 108; y += 4) {
      c.stroke(33, y, 67, y, _chrome, 1);
    }
    c.oval(17, 99, 7, 7, _chrome);
    c.oval(83, 99, 7, 7, _chrome);
    c.oval(17, 99, 5, 5, const Color(0xFFFFF3C4));
    c.oval(83, 99, 5, 5, const Color(0xFFFFF3C4));
  } else {
    c.box(17, 30, 66, 28, _glass, 4);
    c.box(49, 30, 2, 28, cream);
    c.label(places[v % 6], 50, 74, 8, const Color(0xFFFFF3C4), maxW: 80);
    // Roof ladder.
    c.stroke(84, 22, 84, 112, _chrome, 1.2);
    c.stroke(90, 22, 90, 112, _chrome, 1.2);
    for (var y = 30.0; y < 112; y += 10) {
      c.stroke(84, y, 90, y, _chrome, 1);
    }
    c.box(9, 96, 13, 8, const Color(0xFFD6312B), 2);
    c.box(66, 96, 13, 8, const Color(0xFFD6312B), 2);
    c.box(36, 98, 24, 9, const Color(0xFFF4F4F0), 1);
    c.stroke(40, 102.5, 56, 102.5, const Color(0xFF333333), 1);
  }
  c.box(3, 116, 94, 7, const Color(0xFF55585C), 3);
}

void _oxcart(Canvas c, int v, bool front) {
  const wood = Color(0xFF8A5A3A);
  const hay = Color(0xFFD9B455);
  void load() {
    final dome = Path()
      ..moveTo(10, 60)
      ..quadraticBezierTo(8, 14, 45, 10)
      ..quadraticBezierTo(82, 14, 80, 60)
      ..close();
    c.drawPath(dome, Paint()..color = hay);
    final rng = math.Random(11);
    for (var k = 0; k < 30; k++) {
      final x = 14 + rng.nextDouble() * 62;
      final y = 20 + rng.nextDouble() * 36;
      c.stroke(x, y, x + 2, y + 6, shade(hay, -0.25), 0.7);
    }
  }

  c.box(5, 50, 6, 46, shade(wood, -0.3), 2);
  c.box(79, 50, 6, 46, shade(wood, -0.3), 2);
  if (front) {
    load();
    c.box(12, 56, 66, 9, wood, 1);
    const hide = Color(0xFF9A6B45);
    for (final x in [33.0, 51.0]) {
      c.box(x, 74, 6, 22, shade(hide, -0.2), 2);
    }
    c.oval(45, 62, 17, 19, hide);
    c.oval(45, 50, 10, 11, shade(hide, -0.08));
    c.oval(45, 57, 6, 4.5, const Color(0xFF3B2A1E));
    final horn = Paint()
      ..color = const Color(0xFFE6DFC8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    c.drawArc(const Rect.fromLTWH(27, 30, 16, 18), math.pi * 0.2, math.pi * 0.8,
        false, horn);
    c.drawArc(const Rect.fromLTWH(47, 30, 16, 18), 0, math.pi * 0.8, false,
        horn);
    c.stroke(28, 46, 62, 46, wood, 2.4);
  } else {
    load();
    c.box(12, 56, 66, 12, wood, 1);
    for (var x = 18.0; x < 78; x += 9) {
      c.stroke(x, 57, x, 67, shade(wood, -0.3), 0.9);
    }
    c.box(40, 68, 10, 10, shade(wood, -0.2));
    // The carter dozing on top.
    c.box(40, 2, 10, 12, const Color(0xFF7A5540), 3);
    c.poly([33, 4, 57, 4, 45, -5], _hatStraw);
  }
}
