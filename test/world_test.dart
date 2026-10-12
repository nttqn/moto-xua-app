import 'package:flutter_test/flutter_test.dart';
import 'package:moto_xua/core/bikes.dart';
import 'package:moto_xua/core/content.dart';
import 'package:moto_xua/core/track.dart';
import 'package:moto_xua/core/world.dart';

const _dt = 1 / 60;

/// Rides [config] on autopilot until it ends or [maxSeconds] pass.
World _ride(RunConfig config, BikeStats stats,
    {double maxSeconds = 900, int? trafficSeed}) {
  final w = World(config, stats, trafficSeed: trafficSeed);
  const pilot = Autopilot();
  var t = 0.0;
  while (w.phase != Phase.finished && t < maxSeconds) {
    w.update(_dt, pilot.drive(w));
    t += _dt;
  }
  return w;
}

void main() {
  test('tracks are deterministic and close their loop', () {
    for (final theme in ThemeId.values) {
      final a = Track.generate(theme: theme, seed: 3, lengthMeters: 4000,
          hilliness: 0.9, curviness: 0.9);
      final b = Track.generate(theme: theme, seed: 3, lengthMeters: 4000,
          hilliness: 0.9, curviness: 0.9);
      expect(a.segments.length, b.segments.length);
      expect(a.length, greaterThanOrEqualTo(4000));
      expect(a.segments.last.y2.abs(), lessThan(1e-6));
      for (var i = 0; i < a.segments.length; i++) {
        expect(a.segments[i].curve, b.segments[i].curve);
        expect(a.segments[i].scenery.length, b.segments[i].scenery.length);
      }
    }
  });

  test('an open road takes each bike to its top speed', () {
    for (final spec in bikes) {
      final stats = statsFor(spec);
      final w = World(
        RunConfig(mode: RunMode.mission, theme: ThemeId.lua, seed: 1,
            distanceKm: 50, density: 0.0001, curviness: 0, hilliness: 0),
        stats,
      );
      for (var i = 0; i < 60 * 20; i++) {
        w.update(_dt, const Controls());
      }
      expect(w.speedKmh, closeTo(spec.topKmh, 0.5), reason: spec.name);
    }
  });

  test('upgrades make a bike quicker', () {
    final stock = statsFor(bikes.first);
    final tuned = statsAtLevel(bikes.first, maxPartLevel);
    expect(tuned.topSpeed, greaterThan(stock.topSpeed));
    expect(tuned.accel, greaterThan(stock.accel));
    expect(tuned.handling, greaterThan(stock.handling));
  });

  test('hitting oncoming traffic is a crash, a close pass is a near miss', () {
    RunConfig cfg() => const RunConfig(mode: RunMode.mission,
        theme: ThemeId.lua, seed: 1, distanceKm: 50, density: 0.0001,
        curviness: 0, hilliness: 0);
    final stats = statsFor(bikes.first);

    final hit = World(cfg(), stats)..traffic.clear();
    hit.speed = stats.topSpeed;
    hit.x = laneX(1);
    hit.traffic.add(Vehicle(VehicleKind.bus, 1, 60, worldSpeed(40), -1, 0));
    for (var i = 0; i < 120; i++) {
      hit.update(_dt, const Controls());
    }
    expect(hit.crashes, 1);
    expect(hit.fallen || hit.invulnerable > 0, isTrue);

    final close = World(cfg(), stats)..traffic.clear();
    close.speed = stats.topSpeed;
    final bus = Vehicle(VehicleKind.bus, 2, 60, worldSpeed(40), 1, 0);
    close.x = bus.x - (bus.spec.width + kRiderWidth) / 2 - 0.06;
    close.traffic.add(bus);
    for (var i = 0; i < 60 * 6; i++) {
      // Hold the line; the test is about the pass, not the steering.
      close.update(_dt, const Controls());
      close.x = bus.x - (bus.spec.width + kRiderWidth) / 2 - 0.06;
    }
    expect(close.crashes, 0);
    expect(close.overtakes, 1);
    expect(close.nearMisses, 1);
  });

  test('riding the kerb scrapes, riding into a house front is a crash', () {
    const cfg = RunConfig(mode: RunMode.mission, theme: ThemeId.saigon,
        seed: 1, distanceKm: 50, density: 0.0001, curviness: 0, hilliness: 0);
    final stats = statsFor(bikes.first);

    final kerb = World(cfg, stats)..traffic.clear();
    kerb.speed = stats.topSpeed;
    for (var i = 0; i < 60; i++) {
      kerb.x = 1.02;
      kerb.update(_dt, const Controls());
    }
    expect(kerb.scraping, isTrue);
    expect(kerb.crashes, 0);
    expect(kerb.events, contains(WorldEvent.scrape));
    expect(kerb.speed, lessThan(stats.topSpeed));

    final wall = World(cfg, stats)..traffic.clear();
    wall.speed = stats.topSpeed;
    // Hold full lock towards the houses until something gives.
    for (var i = 0; i < 60 * 5 && wall.crashes == 0; i++) {
      wall.update(_dt, const Controls(steer: 1));
    }
    expect(wall.crashes, 1);
    expect(wall.hitProp, isNotNull);
    expect(wall.x.abs(), lessThan(1), reason: 'thrown back onto the road');
  });

  test('every solid roadside object can actually be reached', () {
    for (final theme in ThemeId.values) {
      final t = Track.generate(theme: theme, seed: 2, lengthMeters: 6000);
      for (final s in t.segments) {
        for (final item in s.scenery) {
          final solid = propSolids[item.prop];
          if (solid == null) continue;
          // Nothing solid may reach onto the tarmac itself.
          expect(item.x.abs() - solid.halfWidth, greaterThan(1.0),
              reason: '${item.prop} at ${item.x} in $theme');
        }
      }
    }
  });

  test('an endless run ends when the lives are gone', () {
    final cfg = endlessConfig(ThemeId.saigon, twoWay: true, seed: 4);
    final w = World(cfg, statsFor(bikes.first));
    // No steering at all: sooner or later something is in the way.
    var t = 0.0;
    while (w.phase != Phase.finished && t < 600) {
      w.update(_dt, const Controls());
      t += _dt;
    }
    expect(w.phase, Phase.finished);
    expect(w.lives, 0);
    expect(w.crashes, 3);
  });

  test('every stage can be placed on the bike it is tuned for', () {
    for (var i = 0; i < stages.length; i++) {
      final s = stages[i];
      var best = 99;
      final places = <int>[];
      for (var seed = 0; seed < 4; seed++) {
        final w = _ride(stageConfig(i),
            statsAtLevel(bikeSpec(s.bike), s.rivalLevel), trafficSeed: seed);
        expect(w.phase, Phase.finished, reason: '${s.title} never finished');
        places.add(w.position);
        if (w.position < best) best = w.position;
      }
      // ignore: avoid_print
      print('stage ${i + 1} ${s.title}: places $places');
      expect(best, lessThanOrEqualTo(3), reason: s.title);
    }
  });

  test('delivery and overtaking missions fit their clock', () {
    for (var i = 0; i < missions.length; i++) {
      final m = missions[i];
      if (m.goal == GoalType.nearMiss) continue;
      var wins = 0;
      final notes = <String>[];
      for (var seed = 0; seed < 4; seed++) {
        final w = _ride(missionConfig(i), statsFor(bikeSpec(m.bike)),
            trafficSeed: seed);
        if (w.success) wins++;
        notes.add('${w.success ? "ok" : "FAIL"} ${w.time.toStringAsFixed(0)}s'
            '/${m.timeLimit.toStringAsFixed(0)}s c${w.crashes} o${w.overtakes}');
      }
      // ignore: avoid_print
      print('mission ${i + 1} ${m.title}: $notes');
      expect(wins, greaterThanOrEqualTo(2), reason: m.title);
    }
  });
}
