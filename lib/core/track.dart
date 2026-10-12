/// Road geometry and roadside scenery. Pure Dart.
library;

import 'dart:math' as math;

const double kSegmentLength = 4.0;

/// Half the width of the tarmac, in metres. Sideways positions everywhere
/// are in units of this (-1 = left edge, 1 = right edge).
const double kRoadHalf = 4.5;

const int kLanes = 4;

/// Sideways centre of a lane (0 = leftmost).
double laneX(int lane) => -1 + (lane + 0.5) * (2 / kLanes);

int laneOf(double x) =>
    ((x + 1) / (2 / kLanes)).floor().clamp(0, kLanes - 1).toInt();

enum ThemeId { saigon, hanoi, lua, deo, mientay }

const Map<ThemeId, String> themeNames = {
  ThemeId.saigon: 'Sài Gòn',
  ThemeId.hanoi: 'Hà Nội',
  ThemeId.lua: 'Quốc lộ đồng lúa',
  ThemeId.deo: 'Đèo núi',
  ThemeId.mientay: 'Miền Tây',
};

enum Prop {
  house,
  pole,
  tree,
  bigTree,
  palm,
  banana,
  bamboo,
  haystack,
  buffalo,
  hut,
  milestone,
  billboard,
  stall,
  lamp,
  post,
  rock,
  pine,
  bush,
}

class SceneryItem {
  const SceneryItem(this.prop, this.x, [this.variant = 0]);
  final Prop prop;

  /// Road half-widths from the centre line; beyond +-1 is off the tarmac.
  final double x;
  final int variant;
}

class Segment {
  Segment(this.index, this.curve, this.y1, this.y2);
  final int index;
  final double curve;
  final double y1;
  final double y2;
  final List<SceneryItem> scenery = [];
}

/// A closed loop of segments. Positions along it are unbounded doubles and
/// wrap, so an endless run just keeps lapping.
class Track {
  Track._(this.theme, this.segments);

  final ThemeId theme;
  final List<Segment> segments;

  double get length => segments.length * kSegmentLength;

  Segment segmentAt(double z) {
    final i = (z / kSegmentLength).floor() % segments.length;
    return segments[i < 0 ? i + segments.length : i];
  }

  double heightAt(double z) {
    final s = segmentAt(z);
    final t = (z % kSegmentLength) / kSegmentLength;
    return s.y1 + (s.y2 - s.y1) * (t < 0 ? t + 1 : t);
  }

  /// [curviness] and [hilliness] run 0..1. The same arguments always give
  /// the same road.
  factory Track.generate({
    required ThemeId theme,
    required int seed,
    required double lengthMeters,
    double curviness = 0.5,
    double hilliness = 0.3,
  }) {
    final rng = math.Random(seed);
    final curves = <double>[];
    final heights = <double>[0];
    final wanted = (lengthMeters / kSegmentLength).ceil();

    void addRoad(int enter, int hold, int leave, double curve, double rise) {
      final startY = heights.last;
      final total = enter + hold + leave;
      for (var n = 0; n < total; n++) {
        double c;
        if (n < enter) {
          c = curve * _easeIn(n / enter);
        } else if (n < enter + hold) {
          c = curve;
        } else {
          c = curve * (1 - _easeInOut((n - enter - hold) / leave));
        }
        curves.add(c);
        heights.add(startY + rise * _easeInOut((n + 1) / total));
      }
    }

    // A flat straight to start on, so a race grid is never in a bend.
    addRoad(10, 30, 10, 0, 0);
    while (curves.length < wanted) {
      final roll = rng.nextDouble();
      final len = 12 + rng.nextInt(24);
      final hold = 10 + rng.nextInt(40);
      double curve = 0;
      if (roll < 0.25 + 0.5 * curviness) {
        final strength = 1.2 + rng.nextDouble() * (1.0 + 3.0 * curviness);
        curve = rng.nextBool() ? strength : -strength;
      }
      double rise = 0;
      if (rng.nextDouble() < 0.15 + 0.7 * hilliness) {
        rise = (rng.nextDouble() * 2 - 1) * (6 + 30 * hilliness);
        // Keep the road from wandering off to silly altitudes.
        if ((heights.last + rise).abs() > 60) rise = -rise;
      }
      addRoad(len, hold, len, curve, rise);
    }
    // Come back down to the start height so the loop joins up.
    addRoad(25, 30, 25, 0, -heights.last);

    final segments = <Segment>[
      for (var i = 0; i < curves.length; i++)
        Segment(i, curves[i], heights[i], heights[i + 1]),
    ];
    _dress(segments, theme, rng);
    return Track._(theme, segments);
  }

  static double _easeIn(double t) => t * t;
  static double _easeInOut(double t) => (-math.cos(t * math.pi) / 2) + 0.5;

  static void _dress(List<Segment> segs, ThemeId theme, math.Random rng) {
    for (final s in segs) {
      final i = s.index;
      void put(Prop p, double x, [int v = 0]) =>
          s.scenery.add(SceneryItem(p, x, v));
      bool chance(double p) => rng.nextDouble() < p;
      switch (theme) {
        case ThemeId.saigon:
        case ThemeId.hanoi:
          final hanoi = theme == ThemeId.hanoi;
          // Unbroken rows of tube houses on both sides.
          if (i.isEven) {
            put(Prop.house, -2.15, rng.nextInt(8));
            put(Prop.house, 2.15, rng.nextInt(8));
          }
          if (i % 9 == 0) put(Prop.pole, -1.28, rng.nextInt(2));
          if (i % 9 == 4) put(Prop.pole, 1.28, rng.nextInt(2));
          if (hanoi) {
            if (i % 5 == 1) put(Prop.bigTree, -1.42, rng.nextInt(2));
            if (i % 5 == 3) put(Prop.bigTree, 1.42, rng.nextInt(2));
          } else {
            if (i % 14 == 6) put(Prop.tree, -1.4, rng.nextInt(2));
            if (i % 14 == 12) put(Prop.tree, 1.4, rng.nextInt(2));
            if (i % 11 == 2) put(Prop.lamp, 1.2);
          }
          if (chance(0.06)) {
            put(Prop.stall, chance(0.5) ? -1.45 : 1.45, rng.nextInt(3));
          }
        case ThemeId.lua:
          if (i % 12 == 0) put(Prop.pole, 1.3, rng.nextInt(2));
          if (i % 250 == 30) put(Prop.milestone, 1.14);
          if (chance(0.18)) put(Prop.tree, _side(rng) * (1.5 + rng.nextDouble()));
          if (chance(0.08)) put(Prop.palm, _side(rng) * (2 + rng.nextDouble() * 3), rng.nextInt(2));
          if (chance(0.05)) {
            put(Prop.bamboo, _side(rng) * (1.8 + rng.nextDouble() * 2));
          }
          if (chance(0.05)) {
            put(Prop.haystack, _side(rng) * (2.2 + rng.nextDouble() * 3));
          }
          if (chance(0.04)) {
            put(Prop.buffalo, _side(rng) * (2 + rng.nextDouble() * 3),
                rng.nextInt(2));
          }
          if (chance(0.03)) {
            put(Prop.hut, _side(rng) * (3 + rng.nextDouble() * 3));
          }
          if (chance(0.012)) {
            put(Prop.billboard, _side(rng) * 1.7, rng.nextInt(4));
          }
          if (chance(0.10)) {
            put(Prop.bush, _side(rng) * (1.25 + rng.nextDouble() * 2));
          }
        case ThemeId.deo:
          // Marker posts on the drop side, rock and pine on the hill side.
          if (i % 3 == 0) put(Prop.post, 1.12);
          if (i % 2 == 0) put(Prop.rock, -1.9 - rng.nextDouble(), rng.nextInt(3));
          if (chance(0.22)) put(Prop.pine, -1.6 - rng.nextDouble() * 3);
          if (chance(0.08)) put(Prop.pine, 2.2 + rng.nextDouble() * 3);
          if (chance(0.10)) put(Prop.bush, _side(rng) * (1.3 + rng.nextDouble()));
          if (i % 250 == 30) put(Prop.milestone, -1.14);
        case ThemeId.mientay:
          if (chance(0.34)) put(Prop.palm, -1.4 - rng.nextDouble() * 2.5, rng.nextInt(2));
          if (chance(0.34)) put(Prop.palm, 1.4 + rng.nextDouble() * 2.5, rng.nextInt(2));
          if (chance(0.14)) put(Prop.banana, _side(rng) * (1.35 + rng.nextDouble() * 1.5));
          if (chance(0.04)) put(Prop.hut, _side(rng) * (2.6 + rng.nextDouble() * 3));
          if (chance(0.03)) put(Prop.stall, _side(rng) * 1.5, rng.nextInt(3));
          if (i % 14 == 0) put(Prop.pole, -1.3, rng.nextInt(2));
          if (chance(0.10)) put(Prop.bush, _side(rng) * (1.25 + rng.nextDouble() * 2));
      }
    }
  }

  static double _side(math.Random rng) => rng.nextBool() ? 1 : -1;
}
