import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../core/bikes.dart';
import '../core/track.dart';
import '../core/world.dart';
import 'art_scenery.dart';
import 'art_vehicles.dart';
import 'draw.dart';

class Palette {
  const Palette({
    required this.skyTop,
    required this.skyLow,
    required this.fog,
    required this.groundA,
    required this.groundB,
    required this.vergeA,
    required this.vergeB,
    required this.vergeWidth,
    required this.roadA,
    required this.roadB,
    required this.kerbA,
    required this.kerbB,
    required this.far,
    required this.farKind,
  });

  final Color skyTop;
  final Color skyLow;
  final Color fog;
  final Color groundA;
  final Color groundB;
  final Color vergeA;
  final Color vergeB;

  /// Outer edge of the verge, in road half-widths.
  final double vergeWidth;
  final Color roadA;
  final Color roadB;
  final Color kerbA;
  final Color kerbB;

  /// Colour of the distant silhouette, and its shape: 0 rooftops,
  /// 1 tree line, 2 mountains.
  final Color far;
  final int farKind;

  /// The same place an hour before dark.
  Palette get dusk => Palette(
    skyTop: const Color(0xFF3B3566),
    skyLow: const Color(0xFFF2A65A),
    fog: const Color(0xFFD98F5C),
    groundA: _warm(groundA),
    groundB: _warm(groundB),
    vergeA: _warm(vergeA),
    vergeB: _warm(vergeB),
    vergeWidth: vergeWidth,
    roadA: _warm(roadA),
    roadB: _warm(roadB),
    kerbA: _warm(kerbA),
    kerbB: _warm(kerbB),
    far: const Color(0xFF6B4A66),
    farKind: farKind,
  );

  static Color _warm(Color c) =>
      Color.lerp(shade(c, -0.22), const Color(0xFFE08A4A), 0.16)!;
}

const Map<ThemeId, Palette> palettes = {
  ThemeId.saigon: Palette(
    skyTop: Color(0xFF5FA8DB), skyLow: Color(0xFFD9ECF2), fog: Color(0xFFD5E3E4),
    groundA: Color(0xFFB9B3A4), groundB: Color(0xFFB2AC9D),
    vergeA: Color(0xFFCFC8B6), vergeB: Color(0xFFC6BFAD), vergeWidth: 1.55,
    roadA: Color(0xFF5E5F63), roadB: Color(0xFF58595D),
    kerbA: Color(0xFFF1EFE6), kerbB: Color(0xFF2B2B2B),
    far: Color(0xFFA9B9C4), farKind: 0,
  ),
  ThemeId.hanoi: Palette(
    skyTop: Color(0xFF8FB3C9), skyLow: Color(0xFFE7EBDD), fog: Color(0xFFDDE2D6),
    groundA: Color(0xFFB7AE98), groundB: Color(0xFFAEA590),
    vergeA: Color(0xFFC9BFA6), vergeB: Color(0xFFC0B69D), vergeWidth: 1.6,
    roadA: Color(0xFF636057), roadB: Color(0xFF5C5950),
    kerbA: Color(0xFFE9E4D2), kerbB: Color(0xFF8E3B2E),
    far: Color(0xFF9FB0A8), farKind: 0,
  ),
  ThemeId.lua: Palette(
    skyTop: Color(0xFF4F9FE0), skyLow: Color(0xFFDDF0F2), fog: Color(0xFFD2E6DF),
    groundA: Color(0xFF8CBF4F), groundB: Color(0xFF82B547),
    vergeA: Color(0xFFB98B5E), vergeB: Color(0xFFAE8155), vergeWidth: 1.22,
    roadA: Color(0xFF67666A), roadB: Color(0xFF606064),
    kerbA: Color(0xFFB98B5E), kerbB: Color(0xFFAE8155),
    far: Color(0xFF7FA98C), farKind: 1,
  ),
  ThemeId.deo: Palette(
    skyTop: Color(0xFF6FA6CF), skyLow: Color(0xFFE6EEF0), fog: Color(0xFFDCE6E8),
    groundA: Color(0xFF6E9A58), groundB: Color(0xFF668F52),
    vergeA: Color(0xFFA39683), vergeB: Color(0xFF998C7A), vergeWidth: 1.2,
    roadA: Color(0xFF5B5C60), roadB: Color(0xFF55565A),
    kerbA: Color(0xFFA39683), kerbB: Color(0xFF998C7A),
    far: Color(0xFF7C95AD), farKind: 2,
  ),
  ThemeId.mientay: Palette(
    skyTop: Color(0xFF58AEE0), skyLow: Color(0xFFE2F3EE), fog: Color(0xFFD3EBDD),
    groundA: Color(0xFF6FB05A), groundB: Color(0xFF65A651),
    vergeA: Color(0xFFC2955F), vergeB: Color(0xFFB78A56), vergeWidth: 1.2,
    roadA: Color(0xFF6C6862), roadB: Color(0xFF65615B),
    kerbA: Color(0xFFC2955F), kerbB: Color(0xFFB78A56),
    far: Color(0xFF6FA787), farKind: 1,
  ),
};

/// Lazily drawn, cached pictures of everything that stands on the road.
class SpriteBank {
  final Map<int, Sprite> _props = {};
  final Map<int, Sprite> _vehicles = {};
  final Map<int, Sprite> _riders = {};
  Sprite? _gate;

  Sprite prop(Prop p, int v) =>
      _props[p.index * 16 + v] ??= buildProp(p, v);

  Sprite vehicle(VehicleKind k, int v, bool front) =>
      _vehicles[k.index * 32 + v * 2 + (front ? 1 : 0)] ??=
          buildVehicle(k, v, front);

  Sprite rider(BikeId b, int color) =>
      _riders[b.index * 16 + color] ??= buildRider(b, color);

  Sprite get gate => _gate ??= buildFinishGate();
}

class _Drawable {
  _Drawable(this.sprite, this.sx, this.sy, this.scale, this.depth, this.clip,
      {this.lean = 0, this.fallen = false, this.ghost = false,
      this.flame = false});
  final Sprite sprite;
  final double sx;
  final double sy;
  final double scale;
  final double depth;
  final double clip;
  final double lean;
  final bool fallen;
  final bool ghost;

  /// Throttle wide open: fire out of the pipe.
  final bool flame;
}

/// Paints the classic pseudo-3D road: segments projected one by one,
/// bends faked by sliding each one sideways, hills by real heights.
class RoadRenderer {
  RoadRenderer(this.bank);

  final SpriteBank bank;

  static const int drawSegments = 150;
  static const double cameraHeight = 4.3;
  static const double cameraDepth = 1.05;

  /// How far ahead of the camera the player rides.
  static const double playerDistance = 2.7;

  /// Metres of sideways slide per segment, per unit of curve, per segment.
  static const double curveScale = 0.011;

  /// Everything that stands up is drawn a little larger than life.
  static const double spriteBoost = 1.12;

  final Float64List _sx = Float64List(drawSegments + 1);
  final Float64List _sy = Float64List(drawSegments + 1);
  final Float64List _sw = Float64List(drawSegments + 1);
  final Float64List _clip = Float64List(drawSegments + 1);
  final Float64List _off = Float64List(drawSegments + 1);
  final Float32List _pos = Float32List(drawSegments * 14 * 12);
  final Int32List _col = Int32List(drawSegments * 14 * 6);
  int _quads = 0;
  final List<Paint> _fogPaints = [];
  Color? _fogFor;

  /// Sideways scroll of the far skyline, driven by the bends ridden.
  double skyline = 0;

  void render(Canvas canvas, Size size, World w, double clock) {
    final pal = w.config.dusk
        ? palettes[w.config.theme]!.dusk
        : palettes[w.config.theme]!;
    final track = w.track;
    final half = size.width / 2;
    final horizon = size.height * 0.36;

    final camZ = w.z - playerDistance;
    final camX = w.x * kRoadHalf * 0.82;
    final camY = track.heightAt(w.z) + cameraHeight;

    _sky(canvas, size, pal, horizon, clock);

    final baseIndex = (camZ / kSegmentLength).floor();
    final basePercent = (camZ / kSegmentLength) - baseIndex;
    final n = track.segments.length;
    Segment seg(int i) => track.segments[((baseIndex + i) % n + n) % n];

    // Pass 1, near to far: project every segment boundary.
    var dx = -seg(0).curve * curveScale * basePercent;
    var xoff = 0.0;
    var clip = size.height;
    for (var i = 0; i <= drawSegments; i++) {
      final s = seg(i);
      final z = math.max(0.45, (baseIndex + i) * kSegmentLength - camZ);
      final scale = cameraDepth / z;
      _off[i] = xoff;
      _sx[i] = half + scale * (xoff - camX) * half;
      _sy[i] = horizon - scale * (s.y1 - camY) * half;
      _sw[i] = scale * kRoadHalf * half;
      _clip[i] = clip;
      if (_sy[i] < clip) clip = _sy[i];
      xoff += dx;
      dx += s.curve * curveScale;
    }

    // Pass 2, far to near, so nearer ground simply paints over farther.
    _quads = 0;
    final twoWay = w.config.twoWay;
    final goalIndex = w.config.goalZ > 0
        ? (w.config.goalZ / kSegmentLength).floor()
        : -1;
    for (var i = drawSegments - 1; i >= 0; i--) {
      final y1 = _sy[i], y2 = _sy[i + 1];
      if (y2 >= y1 || y2 > size.height) continue;
      final index = baseIndex + i;
      final fog = math.pow(i / drawSegments, 2.2).toDouble();
      final band = (index ~/ 3).isEven;
      Color f(Color c) => Color.lerp(c, pal.fog, fog)!;

      final x1 = _sx[i], x2 = _sx[i + 1];
      final w1 = _sw[i], w2 = _sw[i + 1];
      _quad(0, y1, size.width, y1, size.width, y2, 0, y2,
          f(band ? pal.groundA : pal.groundB));
      _strip(x1, y1, w1, x2, y2, w2, -pal.vergeWidth, pal.vergeWidth,
          f(band ? pal.vergeA : pal.vergeB));
      _strip(x1, y1, w1, x2, y2, w2, -1.07, 1.07,
          f(index.isEven ? pal.kerbA : pal.kerbB));
      final onLine = index == goalIndex || index == goalIndex + 1;
      _strip(x1, y1, w1, x2, y2, w2, -1, 1,
          f(onLine ? const Color(0xFFF4F1E8) : (band ? pal.roadA : pal.roadB)));
      if (onLine) {
        // Chequered finish line.
        for (var k = 0; k < 8; k++) {
          if ((k + index).isEven) {
            _strip(x1, y1, w1, x2, y2, w2, -1 + k * 0.25, -0.75 + k * 0.25,
                f(const Color(0xFF222222)));
          }
        }
      } else {
        const white = Color(0xFFEDEAE0);
        const yellow = Color(0xFFE8C24A);
        _strip(x1, y1, w1, x2, y2, w2, -0.965, -0.94, f(white));
        _strip(x1, y1, w1, x2, y2, w2, 0.94, 0.965, f(white));
        if (twoWay) {
          _strip(x1, y1, w1, x2, y2, w2, -0.035, -0.012, f(yellow));
          _strip(x1, y1, w1, x2, y2, w2, 0.012, 0.035, f(yellow));
        }
        if (index % 4 < 2) {
          _strip(x1, y1, w1, x2, y2, w2, -0.512, -0.488, f(white));
          _strip(x1, y1, w1, x2, y2, w2, 0.488, 0.512, f(white));
          if (!twoWay) _strip(x1, y1, w1, x2, y2, w2, -0.012, 0.012, f(white));
        }
      }
    }
    if (_quads > 0) {
      final vertices = ui.Vertices.raw(
        ui.VertexMode.triangles,
        Float32List.sublistView(_pos, 0, _quads * 12),
        colors: Int32List.sublistView(_col, 0, _quads * 6),
      );
      canvas.drawVertices(vertices, BlendMode.dst, Paint());
      vertices.dispose();
    }

    // Pass 3: everything standing on the road, far to near.
    _ensureFogPaints(pal.fog);
    final items = <_Drawable>[];

    void place(Sprite sprite, double z, double xUnits,
        {double lean = 0, bool fallen = false, bool ghost = false,
        bool flame = false, double boost = spriteBoost}) {
      final rel = z - camZ;
      // Anything between the camera and the player would fill the screen;
      // it fades out as it drops behind the back wheel.
      if (rel < playerDistance - 1.3) return;
      if (rel < playerDistance - 0.25) ghost = true;
      final fi = rel / kSegmentLength + basePercent;
      final i = fi.floor();
      if (i < 0 || i >= drawSegments) return;
      final t = fi - i;
      final s = seg(i);
      final scale = cameraDepth / rel;
      final off = _off[i] + (_off[i + 1] - _off[i]) * t;
      final y = s.y1 + (s.y2 - s.y1) * t;
      final sx = half + scale * (xUnits * kRoadHalf + off - camX) * half;
      final sy = horizon - scale * (y - camY) * half;
      items.add(_Drawable(sprite, sx, sy, scale * half * boost, rel, _clip[i],
          lean: lean, fallen: fallen, ghost: ghost, flame: flame));
    }

    for (var i = 0; i < drawSegments; i++) {
      final s = seg(i);
      if (s.scenery.isEmpty) continue;
      final z = (baseIndex + i + 0.5) * kSegmentLength;
      for (final item in s.scenery) {
        place(bank.prop(item.prop, item.variant), z, item.x, boost: 1.0);
      }
    }
    if (w.config.goalZ > 0) place(bank.gate, w.config.goalZ, 0, boost: 1.0);
    for (final v in w.traffic) {
      place(bank.vehicle(v.kind, v.variant, v.oncoming), v.z, v.x);
    }
    for (final r in w.racers) {
      place(bank.rider(r.setup.bike, 1 + r.colorIndex % 5), r.z, r.x,
          lean: r.steer * 0.22, flame: r.boostTimer > 0);
    }
    final blink = w.invulnerable > 0 && !w.fallen && (clock * 10).floor().isOdd;
    place(bank.rider(playerBike, 0), w.z, w.x,
        lean: w.steer * 0.26, fallen: w.fallen, ghost: blink,
        flame: w.boosting);
    final me = items.isEmpty ? null : items.last;

    items.sort((a, b) => b.depth.compareTo(a.depth));
    for (final d in items) {
      final wpx = d.sprite.worldW * d.scale;
      if (wpx < 1.5) continue;
      final hpx = d.sprite.worldH * d.scale;
      if (d.sx + wpx / 2 < 0 || d.sx - wpx / 2 > size.width) continue;
      final top = d.sy - hpx;
      if (top > d.clip || top > size.height) continue;
      final fogLevel = (math.pow(d.depth / (drawSegments * kSegmentLength), 1.6) *
              (_fogPaints.length - 1))
          .clamp(0, _fogPaints.length - 1)
          .round();
      final paint = d.ghost ? _ghostPaint : _fogPaints[fogLevel];
      final img = d.sprite.image;
      final src = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
      final needClip = d.sy > d.clip;
      final transformed = d.lean != 0 || d.fallen;
      if (needClip || transformed) canvas.save();
      if (needClip) {
        canvas.clipRect(Rect.fromLTRB(0, 0, size.width, d.clip));
      }
      if (transformed) {
        canvas.translate(d.sx, d.sy);
        canvas.rotate(d.fallen ? 1.35 : d.lean);
        canvas.drawImageRect(
            img, src, Rect.fromLTWH(-wpx / 2, -hpx, wpx, hpx), paint);
      } else {
        canvas.drawImageRect(
            img, src, Rect.fromLTWH(d.sx - wpx / 2, top, wpx, hpx), paint);
      }
      if (needClip || transformed) canvas.restore();
      if (d.flame && !d.fallen && d.sy <= d.clip) {
        _flame(canvas, d.sx + wpx * 0.19, d.sy - wpx * 0.36, wpx, clock);
      }
    }

    if (me != null && w.phase == Phase.running && !w.fallen) {
      _roadsideFx(canvas, w, me, pal, clock);
    }

    if (w.boosting) _speedLines(canvas, size, horizon, clock);

    if (w.config.dusk) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset.zero,
            Offset(0, size.height),
            const [Color(0x333B2A5E), Color(0x22E0703A), Color(0x44201838)],
            const [0, 0.4, 1],
          ),
      );
    }
  }

  /// A flickering tongue of fire at a tail pipe; [unit] is the bike's
  /// width on screen.
  void _flame(Canvas canvas, double x, double y, double unit, double clock) {
    final flick = 0.8 + 0.2 * math.sin(clock * 47) + 0.12 * math.sin(clock * 83);
    void tongue(double w, double h, Color c) {
      canvas.drawOval(
        Rect.fromLTWH(x - unit * w / 2, y - unit * 0.02, unit * w,
            unit * h * flick),
        Paint()..color = c,
      );
    }

    tongue(0.20, 0.52, const Color(0xCCFF5A1E));
    tongue(0.13, 0.38, const Color(0xEEFFB52E));
    tongue(0.07, 0.22, const Color(0xFFFFF6C8));
  }

  /// Streaks rushing out from the vanishing point while flat out.
  void _speedLines(Canvas canvas, Size size, double horizon, double clock) {
    final centre = Offset(size.width / 2, horizon);
    final reach = size.height * 0.75;
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;
    for (var k = 0; k < 40; k++) {
      final phase = clock * 2.6 + k * 0.618;
      final t = phase - phase.floorToDouble();
      final a = _hash(k * 13 + phase.floor() * 7) * math.pi * 2;
      // Keep them off the road ahead, where the rider is looking.
      if (math.sin(a) > 0.2 && math.cos(a).abs() < 0.55) continue;
      final from = 0.35 + t * 0.5, to = from + 0.12 + 0.1 * t;
      paint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.75 * (1 - t));
      canvas.drawLine(
        centre + Offset(math.cos(a), math.sin(a)) * (reach * from),
        centre + Offset(math.cos(a), math.sin(a)) * (reach * to),
        paint,
      );
    }
  }

  /// Sparks off a painted kerb, dust off a dirt one, and a dust trail when
  /// the bike is right off the road. Stateless: every particle's place is
  /// worked out from the clock.
  void _roadsideFx(Canvas canvas, World w, _Drawable me, Palette pal,
      double clock) {
    if (!w.scraping && !(w.offRoad && w.speed > worldSpeed(12))) return;
    final side = w.x >= 0 ? 1.0 : -1.0;
    final unit = me.sprite.worldW * me.scale;
    final ox = me.sx + side * unit * 0.1;
    final oy = me.sy - unit * 0.05;
    final paved = w.config.theme == ThemeId.saigon ||
        w.config.theme == ThemeId.hanoi;

    if (w.scraping && paved) {
      final paint = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = unit * 0.038;
      for (var k = 0; k < 24; k++) {
        final phase = clock * 3.4 + k * 0.618;
        final t = phase - phase.floorToDouble();
        final r1 = _hash(k * 31 + phase.floor() * 17);
        final r2 = _hash(k * 57 + phase.floor() * 29);
        // Thrown back and outward, with a little hop.
        final dx = side * unit * (0.05 + t * (0.25 + 0.7 * r1));
        final dy = unit * (t * (0.35 + 0.5 * r2) -
            math.sin(t * math.pi) * 0.22 * r1);
        final tail = 0.3 * (1 - t);
        paint.color = Color.lerp(const Color(0xFFFFF6C8),
                const Color(0xFFFF8A1E), t)!
            .withValues(alpha: 1 - t * t);
        canvas.drawLine(
          Offset(ox + dx, oy + dy),
          Offset(ox + dx * (1 - tail), oy + dy * (1 - tail) - unit * 0.03),
          paint,
        );
      }
      canvas.drawCircle(Offset(ox, oy), unit * 0.13,
          Paint()..color = const Color(0x55FFB340));
      canvas.drawCircle(Offset(ox, oy), unit * 0.065,
          Paint()..color = const Color(0xEEFFF6C8));
      return;
    }

    // Dirt or pavement grit kicked up behind the wheel.
    final dust = Color.lerp(pal.vergeA, const Color(0xFFFFFFFF), 0.25)!;
    final paint = Paint();
    for (var k = 0; k < 8; k++) {
      final phase = clock * 2.2 + k * 0.618;
      final t = phase - phase.floorToDouble();
      final r1 = _hash(k * 31 + phase.floor() * 17);
      paint.color = dust.withValues(alpha: 0.55 * (1 - t));
      canvas.drawCircle(
        Offset(ox + side * unit * (r1 - 0.3) * 0.5 * t,
            oy + unit * (0.05 + 0.5 * t) - unit * 0.18 * t * r1),
        unit * (0.07 + 0.22 * t),
        paint,
      );
    }
  }

  /// Which bike the player is on; set by the game before the first frame.
  BikeId playerBike = BikeId.cub;

  final Paint _ghostPaint = Paint()
    ..color = const Color(0x77FFFFFF)
    ..filterQuality = FilterQuality.low;

  void _ensureFogPaints(Color fog) {
    if (_fogFor == fog) return;
    _fogFor = fog;
    _fogPaints.clear();
    for (var k = 0; k < 8; k++) {
      final p = Paint()..filterQuality = FilterQuality.low;
      if (k > 0) {
        p.colorFilter = ColorFilter.mode(
          fog.withValues(alpha: k / 7 * 0.85),
          BlendMode.srcATop,
        );
      }
      _fogPaints.add(p);
    }
  }

  void _strip(double x1, double y1, double w1, double x2, double y2, double w2,
      double from, double to, Color c) {
    _quad(x1 + w1 * from, y1, x1 + w1 * to, y1, x2 + w2 * to, y2,
        x2 + w2 * from, y2, c);
  }

  void _quad(double ax, double ay, double bx, double by, double cx, double cy,
      double dx, double dy, Color color) {
    if (_quads * 12 + 12 > _pos.length) return;
    final p = _quads * 12;
    _pos[p] = ax;
    _pos[p + 1] = ay;
    _pos[p + 2] = bx;
    _pos[p + 3] = by;
    _pos[p + 4] = cx;
    _pos[p + 5] = cy;
    _pos[p + 6] = ax;
    _pos[p + 7] = ay;
    _pos[p + 8] = cx;
    _pos[p + 9] = cy;
    _pos[p + 10] = dx;
    _pos[p + 11] = dy;
    final argb = color.toARGB32();
    final q = _quads * 6;
    for (var k = 0; k < 6; k++) {
      _col[q + k] = argb;
    }
    _quads++;
  }

  void _sky(Canvas canvas, Size size, Palette pal, double horizon, double clock) {
    final skyBottom = horizon + size.height * 0.12;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, skyBottom),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, skyBottom),
          [pal.skyTop, pal.skyLow],
        ),
    );
    // Sun, and a few clouds that drift with the bends.
    final dusk = pal.skyTop == const Color(0xFF3B3566);
    final sunX = size.width * 0.72 - skyline * 0.15;
    final sunY = dusk ? horizon - size.height * 0.035 : size.height * 0.09;
    canvas.drawCircle(Offset(sunX, sunY), size.width * (dusk ? 0.085 : 0.06),
        Paint()..color = dusk ? const Color(0xFFFFD08A) : const Color(0xFFFFF6D0));
    final cloud = Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: dusk ? 0.25 : 0.7);
    for (var k = 0; k < 5; k++) {
      final span = size.width * 1.6;
      final cx = ((k * 0.37 * span - skyline * 0.3 + clock * 3) % span + span) %
              span -
          size.width * 0.3;
      final cy = size.height * (0.05 + (k * 0.047) % 0.16);
      final r = size.width * (0.05 + (k % 3) * 0.015);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: r * 3.2, height: r), cloud);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx + r * 0.6, cy - r * 0.35), width: r * 1.8, height: r), cloud);
    }

    // Far silhouette, repeating every 2 screen widths.
    final tile = size.width * 2;
    final shift = ((skyline % tile) + tile) % tile;
    final path = Path();
    for (var rep = -1; rep <= 1; rep++) {
      final ox = rep * tile - shift + tile / 2;
      path.moveTo(ox, skyBottom);
      const steps = 48;
      for (var k = 0; k <= steps; k++) {
        final t = k / steps;
        final x = ox + t * tile;
        double h;
        switch (pal.farKind) {
          case 0:
            // Rooftops: blocky, mostly low, a few taller.
            final cell = (t * 40).floor();
            h = 0.012 + (_hash(cell) * 0.03) + (_hash(cell * 7) > 0.86 ? 0.03 : 0);
            path.lineTo(ox + cell / 40 * tile, horizon - size.height * h);
            path.lineTo(ox + (cell + 1) / 40 * tile, horizon - size.height * h);
            continue;
          case 1:
            h = 0.012 + 0.012 * math.sin(t * math.pi * 14).abs() +
                0.01 * math.sin(t * math.pi * 6 + 1).abs();
          default:
            h = 0.03 + 0.07 * math.sin(t * math.pi * 2).abs() +
                0.04 * math.sin(t * math.pi * 6 + 2).abs() +
                0.015 * math.sin(t * math.pi * 22).abs();
        }
        path.lineTo(x, horizon - size.height * h);
      }
      path.lineTo(ox + tile, skyBottom);
      path.close();
    }
    canvas.drawPath(path, Paint()..color = pal.far);
  }

  static double _hash(int n) {
    final x = math.sin(n * 127.1 + 311.7) * 43758.5453;
    return x - x.floorToDouble();
  }
}
