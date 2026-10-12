import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../core/track.dart';
import 'draw.dart';

const _wallColors = [
  Color(0xFFE6BE62), Color(0xFF8FC4B4), Color(0xFFE5A79D), Color(0xFFECE1C8),
  Color(0xFF9CB8D4), Color(0xFFE2D584), Color(0xFFD6966A), Color(0xFFBDB6A6),
];
const _floors = [2, 3, 3, 4, 2, 3, 4, 3];
const _signs = [
  'PHỞ', 'CÀ PHÊ', 'SỬA XE', 'TẠP HÓA', 'HỚT TÓC', 'CƠM TẤM', 'MAY ĐO',
  'NƯỚC MÍA',
];
const _signColors = [
  Color(0xFFB3261E), Color(0xFF6B3F1D), Color(0xFF1F4E8C), Color(0xFF1E6B45),
  Color(0xFFB3261E), Color(0xFFC77A0A), Color(0xFF5A2A6B), Color(0xFF1E6B45),
];

const _shutter = Color(0xFF3F6B55);
const _iron = Color(0xFF3A3A3A);

Sprite buildProp(Prop prop, int v) {
  switch (prop) {
    case Prop.house:
      final floors = _floors[v % 8];
      final dh = 14.0 + floors * 40 + 46;
      return makeSprite(100, dh, 6.4, 176, (c) => _house(c, v % 8, floors, dh));
    case Prop.pole:
      return makeSprite(60, 170, 3.2, 96, (c) => _pole(c, v));
    case Prop.tree:
      return makeSprite(70, 95, 5.2, 128, (c) => _tree(c, v));
    case Prop.bigTree:
      return makeSprite(90, 150, 7.5, 144, (c) => _bigTree(c, v));
    case Prop.palm:
      return makeSprite(80, 150, 5.4, 128, (c) => _palm(c, v));
    case Prop.banana:
      return makeSprite(60, 70, 3.2, 96, _banana);
    case Prop.bamboo:
      return makeSprite(70, 130, 5.0, 112, _bamboo);
    case Prop.haystack:
      return makeSprite(60, 75, 3.6, 96, _haystack);
    case Prop.buffalo:
      return makeSprite(90, 70, 2.9, 128, (c) => _buffalo(c, v));
    case Prop.hut:
      return makeSprite(110, 75, 6.5, 160, _hut);
    case Prop.milestone:
      return makeSprite(30, 40, 0.8, 48, _milestone);
    case Prop.billboard:
      return makeSprite(120, 90, 6.5, 192, (c) => _billboard(c, v));
    case Prop.stall:
      return makeSprite(80, 80, 3.2, 128, (c) => _stall(c, v));
    case Prop.lamp:
      return makeSprite(40, 130, 2.2, 64, _lamp);
    case Prop.post:
      return makeSprite(12, 30, 0.36, 24, _post);
    case Prop.rock:
      return makeSprite(100, 90, 8.0, 160, (c) => _rock(c, v));
    case Prop.pine:
      return makeSprite(50, 115, 3.8, 96, _pine);
    case Prop.bush:
      return makeSprite(60, 34, 2.4, 96, _bush);
  }
}

/// The banner over the finish line; spans the whole road.
Sprite buildFinishGate() =>
    makeSprite(220, 95, kRoadHalf * 2.5, 384, _finishGate);

void _house(Canvas c, int v, int floors, double dh) {
  final wall = _wallColors[v];
  const roof = 14.0;
  // Roof: rusty tin slope on some, flat parapet with a tank on others.
  if (v.isEven) {
    c.poly([0, roof, 8, 2, 92, 2, 100, roof], const Color(0xFF8A4B3A));
    for (var x = 12.0; x < 92; x += 8) {
      c.stroke(x, 3, x - 2, roof, const Color(0xFF6E3A2D), 0.8);
    }
  } else {
    c.box(2, 8, 96, 6, shade(wall, -0.18));
    c.box(60, 0, 20, 9, const Color(0xFFB9C2C7), 3);
    c.box(64, 8, 3, 3, _iron);
    c.box(74, 8, 3, 3, _iron);
  }
  // The TV aerial every roof had.
  if (v % 3 != 2) {
    c.stroke(22, 12, 22, -2, _iron, 0.9);
    c.stroke(14, 1, 30, 1, _iron, 0.9);
    c.stroke(16, 4, 28, 4, _iron, 0.9);
  }
  c.box(3, roof, 94, dh - roof, wall);
  c.box(3, roof, 5, dh - roof, shade(wall, -0.12));
  c.box(92, roof, 5, dh - roof, shade(wall, -0.2));

  for (var f = 0; f < floors; f++) {
    final y = roof + f * 40;
    // Rain streaks under each slab.
    c.box(10, y + 2, 80, 5, shade(wall, -0.1));
    for (final x in [18.0, 56.0]) {
      c.box(x, y + 8, 26, 27, shade(_shutter, -0.25));
      c.box(x + 1, y + 9, 11.5, 25, _shutter);
      c.box(x + 13.5, y + 9, 11.5, 25, _shutter);
      for (var ly = y + 11; ly < y + 33; ly += 3) {
        c.stroke(x + 2, ly, x + 11.5, ly, shade(_shutter, -0.3), 0.6);
        c.stroke(x + 14.5, ly, x + 24, ly, shade(_shutter, -0.3), 0.6);
      }
    }
    // Balcony slab and iron railing.
    c.box(6, y + 35, 88, 3.5, shade(wall, -0.28));
    c.stroke(8, y + 24, 92, y + 24, _iron, 1);
    for (var x = 9.0; x <= 91; x += 5.5) {
      c.stroke(x, y + 24, x, y + 35, _iron, 0.7);
    }
    // Washing out to dry on some floors.
    if ((v + f).isOdd) {
      const clothes = [
        Color(0xFFF2F2F2), Color(0xFF3B6FB5), Color(0xFFD9534F),
        Color(0xFFF0C24B),
      ];
      for (var k = 0; k < 4; k++) {
        c.box(48 + k * 10.0, y + 25, 7, 8 + (k.isEven ? 2 : 0),
            clothes[(k + v) % 4]);
      }
    }
  }

  final g = dh - 46;
  final sign = _signColors[v];
  c.box(6, g + 1, 88, 13, sign, 1.5);
  c.box(7.5, g + 2.5, 85, 10, shade(sign, -0.15), 1);
  c.label(_signs[v], 50, g + 7.7, 8.5, const Color(0xFFFFE9A8), maxW: 78);
  // Striped canvas awning.
  for (var k = 0; k < 12; k++) {
    final x = 2 + k * 8.0;
    c.poly(
      [x, g + 15, x + 8, g + 15, x + 8 + 1, g + 24, x + 1, g + 24],
      k.isEven ? const Color(0xFFF1EEE4) : shade(sign, 0.15),
    );
  }
  c.box(8, g + 24, 84, 22, const Color(0xFF2E2620));
  // Half-drawn folding iron gate.
  for (var x = 10.0; x < 26; x += 3) {
    c.stroke(x, g + 25, x, g + 46, const Color(0xFF7C8388), 0.8);
  }
  // Goods on the step.
  const goods = [Color(0xFFD9534F), Color(0xFFF0C24B), Color(0xFF5BA36B)];
  for (var k = 0; k < 3; k++) {
    c.box(36 + k * 14.0, g + 36 - (k == 1 ? 4 : 0), 10, 10 + (k == 1 ? 4 : 0),
        goods[(k + v) % 3], 1);
  }
  c.box(0, dh - 2, 100, 2, const Color(0xFF8E8A80));
}

void _pole(Canvas c, int v) {
  const concrete = Color(0xFFA9A69C);
  c.box(27.5, 8, 5, 162, concrete);
  c.box(27.5, 8, 1.5, 162, shade(concrete, -0.2));
  c.box(10, 16, 40, 2.6, const Color(0xFF6B6558));
  c.box(14, 28, 32, 2.6, const Color(0xFF6B6558));
  for (final x in [12.0, 22.0, 38.0, 48.0]) {
    c.box(x - 1, 12, 2, 4, const Color(0xFF3D5A4A));
  }
  // The famous bird's nest of cables.
  final wire = Paint()
    ..color = const Color(0xFF26231F)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8;
  for (var k = 0; k < 6; k++) {
    c.drawOval(
      Rect.fromCenter(
        center: Offset(30 + (k - 3) * 1.2, 36 + k * 1.3),
        width: 14 + k * 2.0,
        height: 7 + k * 1.0,
      ),
      wire,
    );
  }
  for (var k = 0; k < 4; k++) {
    final y = 18.0 + k * 6;
    final sag = Path()
      ..moveTo(0, y - 2)
      ..quadraticBezierTo(15, y + 5, 30, y)
      ..quadraticBezierTo(45, y + 5, 60, y - 2);
    c.drawPath(sag, wire);
  }
  if (v == 1) {
    // Ward loudspeakers.
    for (final dir in [-1.0, 1.0]) {
      c.poly([30, 54, 30 + dir * 14, 48, 30 + dir * 14, 62, 30, 58],
          const Color(0xFF8D9499));
      c.oval(30 + dir * 14, 55, 2, 7, const Color(0xFF5E666B));
    }
  } else {
    c.box(21, 50, 18, 16, const Color(0xFF7A8187), 2);
    c.box(23, 53, 14, 2, const Color(0xFF596066));
  }
}

void _tree(Canvas c, int v) {
  c.box(31, 55, 8, 40, const Color(0xFF6B4A2F));
  c.box(31, 55, 3, 40, const Color(0xFF52371F));
  const leaf = Color(0xFF3F7D3A);
  c.oval(35, 36, 30, 26, shade(leaf, -0.2));
  c.oval(24, 30, 20, 18, leaf);
  c.oval(46, 28, 20, 18, leaf);
  c.oval(35, 20, 20, 16, shade(leaf, 0.12));
  if (v == 1) {
    // Flame tree in bloom.
    final rng = math.Random(7);
    for (var k = 0; k < 40; k++) {
      c.oval(10 + rng.nextDouble() * 50, 8 + rng.nextDouble() * 44, 2.2, 1.8,
          const Color(0xFFD8402C));
    }
  }
}

void _bigTree(Canvas c, int v) {
  const bark = Color(0xFF5E4630);
  c.poly([38, 150, 41, 70, 49, 70, 52, 150], bark);
  c.poly([41, 80, 24, 52, 28, 50, 45, 72], bark);
  c.poly([49, 80, 66, 50, 62, 48, 46, 72], bark);
  // Lime-washed foot.
  c.poly([38, 150, 39.2, 122, 50.8, 122, 52, 150], const Color(0xFFEDEBE2));
  final leaf = v == 0 ? const Color(0xFF2F6B37) : const Color(0xFF3C7A2E);
  c.oval(45, 46, 43, 36, shade(leaf, -0.25));
  c.oval(24, 44, 22, 20, leaf);
  c.oval(64, 40, 24, 22, leaf);
  c.oval(44, 24, 28, 22, shade(leaf, 0.1));
  c.oval(30, 20, 12, 9, shade(leaf, 0.22));
}

void _palm(Canvas c, int v) {
  const trunk = Color(0xFF8A7A5C);
  final lean = v == 0 ? 6.0 : -8.0;
  final path = Path()
    ..moveTo(37, 150)
    ..quadraticBezierTo(40 + lean, 100, 40 + lean * 0.6, 42)
    ..lineTo(45 + lean * 0.6, 42)
    ..quadraticBezierTo(46 + lean, 100, 44, 150)
    ..close();
  c.drawPath(path, Paint()..color = trunk);
  for (var y = 60.0; y < 150; y += 9) {
    c.stroke(38 + lean * 0.5, y, 45 + lean * 0.5, y, shade(trunk, -0.25), 0.8);
  }
  final cx = 42.5 + lean * 0.6;
  const cy = 42.0;
  const frond = Color(0xFF3E8B43);
  for (var k = 0; k < 9; k++) {
    final a = -math.pi + k * math.pi / 8;
    final ex = cx + math.cos(a) * 38;
    final ey = cy + math.sin(a) * 26 + 14;
    final leaf = Path()
      ..moveTo(cx, cy)
      ..quadraticBezierTo(cx + math.cos(a) * 24, cy + math.sin(a) * 30 - 8, ex,
          ey)
      ..quadraticBezierTo(cx + math.cos(a) * 20, cy + math.sin(a) * 18, cx,
          cy + 3)
      ..close();
    c.drawPath(leaf, Paint()..color = k.isEven ? frond : shade(frond, -0.2));
  }
  for (final d in [-3.0, 2.0, 6.0]) {
    c.oval(cx + d, cy + 5, 3, 3.4, const Color(0xFF6E8B2F));
  }
}

void _banana(Canvas c) {
  c.box(27, 34, 6, 36, const Color(0xFF8FA85A));
  const leaf = Color(0xFF5FA046);
  for (var k = 0; k < 6; k++) {
    final a = -math.pi + 0.25 + k * (math.pi - 0.5) / 5;
    c.save();
    c.translate(30, 36);
    c.rotate(a + math.pi / 2);
    c.oval(0, -17, 6.5, 19, k.isEven ? leaf : shade(leaf, -0.18));
    c.stroke(0, 0, 0, -34, shade(leaf, 0.3), 0.7);
    c.restore();
  }
}

void _bamboo(Canvas c) {
  final rng = math.Random(3);
  for (var k = 0; k < 9; k++) {
    final x0 = 22 + k * 3.2;
    final lean = (k - 4) * 5.0 + rng.nextDouble() * 4;
    final stalk = Path()
      ..moveTo(x0, 130)
      ..quadraticBezierTo(x0 + lean * 0.3, 70, x0 + lean, 12 + rng.nextDouble() * 14);
    c.drawPath(
      stalk,
      Paint()
        ..color = k.isEven ? const Color(0xFF8FAE4C) : const Color(0xFF6E9440)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
    for (var j = 0; j < 5; j++) {
      c.oval(x0 + lean * (0.5 + j * 0.1) + rng.nextDouble() * 8 - 4,
          60 - j * 10.0 + rng.nextDouble() * 6, 7, 2.6, const Color(0xFF4F8A3A));
    }
  }
}

void _haystack(Canvas c) {
  c.stroke(30, 4, 30, 30, const Color(0xFF6B4A2F), 1.6);
  const hay = Color(0xFFD9B455);
  final dome = Path()
    ..moveTo(4, 75)
    ..quadraticBezierTo(2, 30, 30, 14)
    ..quadraticBezierTo(58, 30, 56, 75)
    ..close();
  c.drawPath(dome, Paint()..color = hay);
  final rng = math.Random(5);
  for (var k = 0; k < 26; k++) {
    final x = 8 + rng.nextDouble() * 44;
    final y = 28 + rng.nextDouble() * 44;
    c.stroke(x, y, x + 2, y + 6, shade(hay, -0.25), 0.7);
  }
}

void _buffalo(Canvas c, int v) {
  const hide = Color(0xFF4A4648);
  for (final x in [22.0, 32.0, 58.0, 68.0]) {
    c.box(x, 46, 6, 24, shade(hide, -0.2), 2);
  }
  c.oval(46, 42, 30, 15, hide);
  c.oval(16, 36, 11, 9, hide);
  c.oval(9, 40, 6, 5, shade(hide, -0.15));
  final horn = Paint()
    ..color = const Color(0xFFD8D2C4)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.2
    ..strokeCap = StrokeCap.round;
  c.drawArc(const Rect.fromLTWH(8, 14, 22, 20), math.pi * 0.9, math.pi * 0.9,
      false, horn);
  c.stroke(76, 36, 82, 52, hide, 1.6);
  if (v == 1) {
    // The kid with the flute.
    c.box(42, 16, 9, 14, const Color(0xFF8A5A3A), 2);
    c.oval(46.5, 12, 4, 4, const Color(0xFFE2B58E));
    c.poly([36, 11, 57, 11, 46.5, 3], const Color(0xFFE8D9A6));
    c.stroke(46, 14, 34, 18, const Color(0xFF6B4A2F), 1);
  }
}

void _hut(Canvas c) {
  c.box(14, 38, 82, 37, const Color(0xFFB79A62));
  for (var x = 18.0; x < 96; x += 5) {
    c.stroke(x, 38, x, 75, const Color(0xFF97804E), 0.7);
  }
  c.box(46, 48, 16, 27, const Color(0xFF2E2620));
  c.box(72, 48, 14, 11, const Color(0xFF3B332B));
  c.poly([2, 42, 30, 6, 80, 6, 108, 42], const Color(0xFF9A7B45));
  c.poly([2, 42, 30, 6, 36, 6, 12, 42], const Color(0xFF7D6335));
  for (var x = 14.0; x < 104; x += 7) {
    c.stroke(x, 40, x + 6, 22, const Color(0xFF7D6335), 0.7);
  }
}

void _milestone(Canvas c) {
  c.box(4, 10, 22, 30, const Color(0xFFEFEDE4), 2);
  final cap = Path()
    ..addRRect(RRect.fromRectAndCorners(const Rect.fromLTWH(4, 2, 22, 14),
        topLeft: const Radius.circular(11), topRight: const Radius.circular(11)));
  c.drawPath(cap, Paint()..color = const Color(0xFFC0392B));
  c.label('QL1', 15, 9.5, 6, const Color(0xFFFFFFFF));
  c.label('KM', 15, 26, 7, const Color(0xFF2B2B2B));
}

void _billboard(Canvas c, int v) {
  const texts = [
    ['AN TOÀN', 'LÀ BẠN'],
    ['NƯỚC MẮM', 'CÁ CƠM'],
    ['BIA HƠI', 'MÁT LẠNH'],
    ['XÀ BÔNG', 'THƠM LÂU'],
  ];
  const bg = [
    Color(0xFFB3261E), Color(0xFF1F4E8C), Color(0xFFE0A21A), Color(0xFF1E6B45),
  ];
  const fg = [
    Color(0xFFFFE27A), Color(0xFFFFFFFF), Color(0xFF7A1A12), Color(0xFFFFF3C4),
  ];
  c.box(22, 50, 4, 40, const Color(0xFF6B6558));
  c.box(94, 50, 4, 40, const Color(0xFF6B6558));
  c.box(2, 2, 116, 52, const Color(0xFFEDE6D2), 2);
  c.box(5, 5, 110, 46, bg[v % 4], 1);
  c.label(texts[v % 4][0], 60, 19, 13, fg[v % 4], maxW: 100);
  c.label(texts[v % 4][1], 60, 37, 13, fg[v % 4], maxW: 100);
}

void _stall(Canvas c, int v) {
  if (v == 0) {
    // Iced tea under a beach umbrella.
    c.stroke(40, 14, 40, 78, const Color(0xFF8A8F94), 1.4);
    const seg = [Color(0xFFD9534F), Color(0xFFF2F2F2), Color(0xFF3B6FB5),
      Color(0xFFF2F2F2)];
    for (var k = 0; k < 4; k++) {
      c.poly([40, 6, 4 + k * 18.0, 28, 22 + k * 18.0, 28], seg[k]);
    }
    c.box(22, 54, 36, 3, const Color(0xFF8A5A3A));
    c.box(25, 57, 3, 21, const Color(0xFF6B4A2F));
    c.box(52, 57, 3, 21, const Color(0xFF6B4A2F));
    for (var k = 0; k < 4; k++) {
      c.box(26 + k * 7.5, 46, 5, 8, const Color(0xCCBFE3E0), 1);
    }
    c.box(8, 66, 10, 12, const Color(0xFFD9534F), 1.5);
    c.box(62, 66, 10, 12, const Color(0xFF3B6FB5), 1.5);
  } else if (v == 1) {
    // Bread cart.
    c.box(14, 22, 52, 30, const Color(0xCCDDEBEE), 1);
    c.box(14, 22, 52, 9, const Color(0xFFE0A21A));
    c.label('BÁNH MÌ', 40, 26.5, 6.5, const Color(0xFF7A1A12), maxW: 48);
    for (var k = 0; k < 5; k++) {
      c.oval(22 + k * 9.0, 44, 4, 2.4, const Color(0xFFD9A555));
    }
    c.box(12, 52, 56, 16, const Color(0xFF3B6FB5), 1);
    c.oval(24, 72, 7, 7, const Color(0xFF2B2B2B));
    c.oval(56, 72, 7, 7, const Color(0xFF2B2B2B));
    c.oval(24, 72, 3, 3, const Color(0xFF9AA0A5));
    c.oval(56, 72, 3, 3, const Color(0xFF9AA0A5));
  } else {
    // Kerbside puncture repair.
    c.box(10, 30, 26, 18, const Color(0xFFEDE6D2), 1);
    c.label('VÁ XE', 23, 39, 7, const Color(0xFFB3261E), maxW: 22);
    c.stroke(23, 48, 23, 78, const Color(0xFF6B4A2F), 1.6);
    final tyre = Paint()
      ..color = const Color(0xFF222222)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    c.drawCircle(const Offset(54, 40), 11, tyre);
    c.drawCircle(const Offset(60, 64), 11, tyre);
    c.box(38, 68, 8, 10, const Color(0xFFC0392B), 1);
  }
}

void _lamp(Canvas c) {
  c.box(18, 14, 3, 116, const Color(0xFF6E757A));
  final arm = Paint()
    ..color = const Color(0xFF6E757A)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.2;
  c.drawArc(const Rect.fromLTWH(-2, 4, 22, 22), -math.pi / 2, math.pi / 2,
      false, arm);
  c.oval(7, 6, 6, 2.6, const Color(0xFFF5E7A8));
}

void _post(Canvas c) {
  c.box(2, 2, 8, 28, const Color(0xFFF2F0E8), 1.5);
  c.box(2, 2, 8, 8, const Color(0xFFC0392B), 1.5);
}

void _rock(Canvas c, int v) {
  const stone = Color(0xFF8C8173);
  final tops = [
    [0.0, 90.0, 6.0, 40.0, 26.0, 12.0, 52.0, 4.0, 78.0, 20.0, 96.0, 52.0, 100.0, 90.0],
    [0.0, 90.0, 10.0, 30.0, 40.0, 8.0, 66.0, 22.0, 90.0, 14.0, 100.0, 90.0],
    [0.0, 90.0, 4.0, 54.0, 30.0, 24.0, 60.0, 30.0, 84.0, 6.0, 100.0, 50.0, 100.0, 90.0],
  ][v % 3];
  c.poly(tops, stone);
  c.poly([tops[2], tops[3], tops[4], tops[5], tops[4] + 8, 90, 0, 90],
      shade(stone, -0.18));
  c.poly([tops[4], tops[5], tops[6], tops[7], tops[6] - 4, 50, tops[4] + 8, 60],
      shade(stone, 0.14));
  // Scrub clinging on.
  c.oval(30, 60, 12, 6, const Color(0xFF4E7A3C));
  c.oval(72, 70, 14, 7, const Color(0xFF5A8742));
}

void _pine(Canvas c) {
  c.box(22, 84, 6, 31, const Color(0xFF5E4630));
  const needle = Color(0xFF2C5D3D);
  for (var k = 0; k < 4; k++) {
    final y = 8 + k * 21.0;
    final half = 12 + k * 4.0;
    c.poly([25, y, 25 - half, y + 30, 25 + half, y + 30],
        k.isEven ? needle : shade(needle, 0.1));
  }
}

void _bush(Canvas c) {
  const leaf = Color(0xFF4E8A3C);
  c.oval(18, 22, 16, 12, shade(leaf, -0.15));
  c.oval(40, 20, 18, 14, leaf);
  c.oval(30, 14, 12, 9, shade(leaf, 0.15));
}

void _finishGate(Canvas c) {
  c.box(6, 6, 6, 89, const Color(0xFF8A5A3A));
  c.box(208, 6, 6, 89, const Color(0xFF8A5A3A));
  c.box(10, 6, 200, 26, const Color(0xFFB3261E), 2);
  c.box(13, 9, 194, 20, const Color(0xFF9B1E17), 1);
  c.label('ĐÍCH', 110, 19.5, 18, const Color(0xFFFFE27A), maxW: 180);
  // Bunting.
  const flags = [Color(0xFFF0C24B), Color(0xFF3B6FB5), Color(0xFFD9534F),
    Color(0xFF5BA36B), Color(0xFFF2F2F2)];
  for (var k = 0; k < 24; k++) {
    final x = 14 + k * 8.2;
    c.poly([x, 33, x + 7, 33, x + 3.5, 42], flags[k % 5]);
  }
}
