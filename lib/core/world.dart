/// The whole ride simulation: player, traffic, rivals, goals. Pure Dart.
library;

import 'dart:math' as math;

import 'bikes.dart';
import 'track.dart';

enum VehicleKind { bicycle, cyclo, moto, lam, car, truck, bus, oxcart }

class VehicleSpec {
  const VehicleSpec(this.width, this.length, this.minKmh, this.maxKmh);

  /// In road half-widths.
  final double width;

  /// World metres.
  final double length;
  final double minKmh;
  final double maxKmh;
}

const Map<VehicleKind, VehicleSpec> vehicleSpecs = {
  VehicleKind.bicycle: VehicleSpec(0.14, 1.8, 12, 18),
  VehicleKind.cyclo: VehicleSpec(0.25, 2.6, 9, 14),
  VehicleKind.moto: VehicleSpec(0.16, 2.0, 32, 50),
  VehicleKind.lam: VehicleSpec(0.31, 3.0, 26, 38),
  VehicleKind.car: VehicleSpec(0.38, 4.2, 40, 56),
  VehicleKind.truck: VehicleSpec(0.46, 6.5, 30, 46),
  VehicleKind.bus: VehicleSpec(0.47, 9.0, 36, 52),
  VehicleKind.oxcart: VehicleSpec(0.34, 3.4, 5, 8),
};

/// How wide the player and rivals count as, in road half-widths.
const double kRiderWidth = 0.12;

class Vehicle {
  Vehicle(this.kind, this.lane, this.z, this.cruise, this.dir, this.variant)
    : x = laneX(lane),
      speed = cruise;

  final VehicleKind kind;
  final int lane;
  double z;
  final double x;

  /// Unsigned cruising speed, world m/s.
  final double cruise;
  double speed;

  /// 1 = going the player's way, -1 = oncoming.
  final int dir;
  final int variant;

  /// Whether it was ahead of the player last tick.
  bool ahead = true;
  bool counted = false;

  VehicleSpec get spec => vehicleSpecs[kind]!;
  bool get oncoming => dir < 0;
}

class RivalSetup {
  const RivalSetup(this.name, this.bike, {this.level = 0, this.skill = 0.9});
  final String name;
  final BikeId bike;
  final int level;

  /// Fraction of the bike's top speed this rider is willing to hold.
  final double skill;
}

class Racer {
  Racer(this.setup, this.z, this.x, this.colorIndex)
    : stats = statsAtLevel(bikeSpec(setup.bike), setup.level),
      lane = laneOf(x);

  final RivalSetup setup;
  final BikeStats stats;
  final int colorIndex;
  double z;
  double x;
  double speed = 0;
  double steer = 0;
  int lane;
  double? finishTime;
}

enum RunMode { endless, race, mission }

enum GoalType { deliver, overtake, nearMiss }

class RunConfig {
  const RunConfig({
    required this.mode,
    required this.theme,
    required this.seed,
    this.distanceKm = 0,
    this.curviness = 0.4,
    this.hilliness = 0.3,
    this.density = 2.0,
    this.twoWay = false,
    this.rivals = const [],
    this.timeLimit = 0,
    this.maxCrashes = -1,
    this.goal = GoalType.deliver,
    this.goalCount = 0,
    this.lives = 3,
    this.dusk = false,
  });

  final RunMode mode;
  final ThemeId theme;
  final int seed;

  /// Distance to the finish line as the player reads it (race, delivery).
  final double distanceKm;
  final double curviness;
  final double hilliness;

  /// Vehicles per 100 world metres of road.
  final double density;

  /// Left two lanes carry oncoming traffic.
  final bool twoWay;
  final List<RivalSetup> rivals;

  /// Seconds; 0 = no clock.
  final double timeLimit;

  /// More crashes than this fails the run; -1 = unlimited.
  final int maxCrashes;
  final GoalType goal;
  final int goalCount;
  final int lives;
  final bool dusk;

  double get goalZ => distanceKm * 1000 * kSpeedScale;
}

class Controls {
  const Controls({this.steer = 0, this.brake = false});

  /// -1 full left .. 1 full right.
  final double steer;
  final bool brake;
}

enum Phase { countdown, running, finished }

enum WorldEvent { go, crash, bump, scrape, nearMiss, overtake, finish, fail }

/// The kerb runs from here ...
const double kKerbInner = 0.95;

/// ... to here; beyond it is pavement or dirt.
const double kKerbOuter = 1.1;

/// As far off the road as a bike can get.
const double kVergeLimit = 1.5;

class Solid {
  const Solid(this.halfWidth, [this.depth = 1.4]);

  /// In road half-widths.
  final double halfWidth;

  /// Metres either side of the object along the road.
  final double depth;
}

/// Roadside scenery that cannot be ridden through. House fronts are deep
/// enough to join into an unbroken wall; bushes are left soft.
const Map<Prop, Solid> propSolids = {
  Prop.house: Solid(0.71, 4.1),
  Prop.pole: Solid(0.05),
  Prop.lamp: Solid(0.05),
  Prop.tree: Solid(0.07),
  Prop.bigTree: Solid(0.10),
  Prop.palm: Solid(0.06),
  Prop.banana: Solid(0.10),
  Prop.bamboo: Solid(0.25),
  Prop.haystack: Solid(0.30, 1.8),
  Prop.buffalo: Solid(0.28, 1.6),
  Prop.hut: Solid(0.60, 2.5),
  Prop.milestone: Solid(0.07),
  Prop.billboard: Solid(0.50),
  Prop.stall: Solid(0.30, 1.6),
  Prop.post: Solid(0.04, 1.0),
  Prop.rock: Solid(0.80, 3.0),
  Prop.pine: Solid(0.06),
};

/// Which traffic turns up where.
const Map<ThemeId, List<VehicleKind>> _trafficMix = {
  ThemeId.saigon: [
    VehicleKind.bicycle, VehicleKind.bicycle, VehicleKind.cyclo,
    VehicleKind.cyclo, VehicleKind.moto, VehicleKind.moto, VehicleKind.moto,
    VehicleKind.lam, VehicleKind.lam, VehicleKind.car, VehicleKind.bus,
  ],
  ThemeId.hanoi: [
    VehicleKind.bicycle, VehicleKind.bicycle, VehicleKind.bicycle,
    VehicleKind.bicycle, VehicleKind.cyclo, VehicleKind.cyclo,
    VehicleKind.moto, VehicleKind.moto, VehicleKind.car, VehicleKind.bus,
  ],
  ThemeId.lua: [
    VehicleKind.bicycle, VehicleKind.moto, VehicleKind.moto,
    VehicleKind.oxcart, VehicleKind.truck, VehicleKind.truck,
    VehicleKind.bus, VehicleKind.bus, VehicleKind.lam, VehicleKind.car,
  ],
  ThemeId.deo: [
    VehicleKind.truck, VehicleKind.truck, VehicleKind.truck,
    VehicleKind.bus, VehicleKind.bus, VehicleKind.moto, VehicleKind.car,
  ],
  ThemeId.mientay: [
    VehicleKind.bicycle, VehicleKind.bicycle, VehicleKind.moto,
    VehicleKind.moto, VehicleKind.lam, VehicleKind.lam, VehicleKind.oxcart,
    VehicleKind.bus, VehicleKind.truck,
  ],
};

class World {
  World(this.config, this.stats, {int? trafficSeed})
    : track = Track.generate(
        theme: config.theme,
        seed: config.seed,
        // Endless runs lap a long loop; the others get road past the line.
        lengthMeters: config.goalZ > 0 ? config.goalZ + 400 : 9000,
        curviness: config.curviness,
        hilliness: config.hilliness,
      ),
      _rng = math.Random(trafficSeed ?? config.seed * 31 + 7),
      lives = config.lives {
    var i = 0;
    for (final setup in config.rivals) {
      // Two abreast, the player starts at the back.
      final row = (config.rivals.length - 1 - i) ~/ 2 + 1;
      racers.add(Racer(setup, row * 7.0, i.isEven ? -0.3 : 0.3, i));
      i++;
    }
    if (config.mode != RunMode.race) {
      phase = Phase.running;
      countdown = 0;
    }
    _spawnZ = 90;
    _spawn();
  }

  final RunConfig config;
  final BikeStats stats;
  final Track track;
  final math.Random _rng;

  final List<Vehicle> traffic = [];
  final List<Racer> racers = [];
  final List<WorldEvent> events = [];

  Phase phase = Phase.countdown;
  double countdown = 3.2;

  double z = 0;
  double x = 0;
  double speed = 0;
  double steer = 0;
  double time = 0;

  /// Seconds left lying on the tarmac after a crash.
  double crashTimer = 0;
  double invulnerable = 0;
  double _bumpCooldown = 0;

  int lives;
  int crashes = 0;
  int overtakes = 0;
  int nearMisses = 0;
  int combo = 0;
  int bestCombo = 0;
  double comboTimer = 0;
  int bonus = 0;

  /// Race finishing place, or the live place while still riding.
  int position = 1;
  bool success = false;
  String failReason = '';

  double _spawnZ = 0;

  /// What the last crash was into; for tuning and tests.
  String lastHit = '';

  /// The roadside object of the last crash, or null if it was a vehicle.
  Prop? hitProp;

  /// Wheels on the kerb right now.
  bool scraping = false;

  /// Past the kerb, on the pavement or the dirt.
  bool offRoad = false;
  double _scrapeCooldown = 0;

  bool get fallen => crashTimer > 0;
  double get speedKmh => shownKmh(speed);
  double get distanceMeters => z / kSpeedScale;
  double get remainingMeters =>
      math.max(0, (config.goalZ - z) / kSpeedScale).toDouble();
  double get timeLeft => math.max(0, config.timeLimit - time).toDouble();
  bool get inOncomingLane => config.twoWay && x < 0 && x > -1;
  int get score => distanceMeters.round() + bonus;

  /// 0..1 through whatever this run is counting.
  double get progress {
    switch (config.goal) {
      case GoalType.deliver:
        return config.goalZ <= 0 ? 0 : (z / config.goalZ).clamp(0, 1).toDouble();
      case GoalType.overtake:
        return (overtakes / config.goalCount).clamp(0, 1).toDouble();
      case GoalType.nearMiss:
        return (nearMisses / config.goalCount).clamp(0, 1).toDouble();
    }
  }

  double get _density {
    if (config.mode != RunMode.endless) return config.density;
    // Endless traffic thickens over the first few kilometres.
    return config.density + math.min(2.6, distanceMeters / 1600);
  }

  void update(double dt, Controls controls) {
    if (phase == Phase.finished) {
      speed = math.max(0, speed - worldSpeed(30) * dt);
      steer += (0 - steer) * math.min(1, dt * 6);
      z += speed * dt;
      _moveTraffic(dt);
      _moveRacers(dt);
      return;
    }
    if (phase == Phase.countdown) {
      countdown -= dt;
      _moveTraffic(dt);
      if (countdown <= 0) {
        phase = Phase.running;
        events.add(WorldEvent.go);
      }
      return;
    }
    time += dt;
    _movePlayer(dt, controls);
    _moveTraffic(dt);
    _moveRacers(dt);
    _collide(dt);
    _spawn();
    _checkEnd();
  }

  void _movePlayer(double dt, Controls c) {
    if (invulnerable > 0) invulnerable -= dt;
    if (_bumpCooldown > 0) _bumpCooldown -= dt;
    if (comboTimer > 0) {
      comboTimer -= dt;
      if (comboTimer <= 0) combo = 0;
    }
    if (crashTimer > 0) {
      crashTimer -= dt;
      speed = 0;
      scraping = false;
      steer += (0 - steer) * math.min(1, dt * 6);
      return;
    }
    steer += (c.steer.clamp(-1, 1) - steer) * math.min(1, dt * 9);
    final top = stats.topSpeed;
    if (c.brake) {
      speed -= worldSpeed(70) * dt;
    } else {
      speed += stats.accel * (top * 1.03 - speed) * dt;
    }
    final edge = x.abs();
    offRoad = edge > kKerbOuter;
    scraping = edge > kKerbInner && !offRoad && speed > worldSpeed(15);
    if (offRoad && speed > top * 0.4) speed -= worldSpeed(60) * dt;
    if (scraping) {
      // Grinding along the kerb scrubs speed and makes itself heard.
      if (speed > top * 0.6) speed -= worldSpeed(28) * dt;
      _scrapeCooldown -= dt;
      if (_scrapeCooldown <= 0) {
        events.add(WorldEvent.scrape);
        _scrapeCooldown = 0.22;
      }
    } else {
      _scrapeCooldown = 0;
    }
    speed = speed.clamp(0, top).toDouble();

    final sp = speed / top;
    final curve = track.segmentAt(z).curve;
    x += steer * stats.handling * (0.3 + 0.7 * sp) * dt;
    x -= curve * sp * sp * (0.13 / stats.grip) * dt;
    x = x.clamp(-kVergeLimit, kVergeLimit).toDouble();
    z += speed * dt;

    if (inOncomingLane && speed > top * 0.6) {
      // Riding into the oncoming stream pays, a little, all the time.
      _oncomingCarry += speed * dt / kSpeedScale;
      if (_oncomingCarry >= 10) {
        bonus += 10;
        _oncomingCarry -= 10;
      }
    }
  }

  double _oncomingCarry = 0;

  void _moveTraffic(double dt) {
    for (final v in traffic) {
      // Same-way vehicles tuck in behind whatever is slower in their lane.
      var target = v.cruise;
      if (!v.oncoming) {
        for (final o in traffic) {
          if (identical(o, v) || o.lane != v.lane || o.oncoming) continue;
          final gap = o.z - v.z;
          if (gap > 0 && gap < (o.spec.length + v.spec.length) / 2 + 8) {
            target = math.min(target, o.speed);
          }
        }
      }
      v.speed = target;
      v.z += v.speed * v.dir * dt;
    }
    traffic.removeWhere((v) => v.z < z - 40 || v.z > z + 900);
  }

  void _spawn() {
    final frontier = z + 640;
    while (_spawnZ < frontier) {
      final density = _density;
      final mix = _trafficMix[config.theme]!;
      final kind = mix[_rng.nextInt(mix.length)];
      final lane = _rng.nextInt(kLanes);
      final oncoming = config.twoWay && lane < kLanes ~/ 2;
      final spec = vehicleSpecs[kind]!;
      final kmh = spec.minKmh + _rng.nextDouble() * (spec.maxKmh - spec.minKmh);
      final clear = traffic.every(
        (o) => o.lane != lane || (o.z - _spawnZ).abs() > 18,
      );
      if (clear) {
        traffic.add(
          Vehicle(kind, lane, _spawnZ, worldSpeed(kmh), oncoming ? -1 : 1,
              _rng.nextInt(6)),
        );
      }
      _spawnZ += (100 / density) * (0.45 + _rng.nextDouble() * 1.1);
    }
  }

  void _collide(double dt) {
    for (final v in traffic) {
      final dz = v.z - z;
      final dx = v.x - x;
      final reach = v.spec.length / 2 + 0.9;
      final wide = (v.spec.width + kRiderWidth) / 2;

      if (invulnerable <= 0 && crashTimer <= 0 && dz.abs() < reach &&
          dx.abs() < wide) {
        final closing = speed - v.speed * v.dir;
        if (!v.oncoming && dz > 0 && closing < worldSpeed(22)) {
          // A soft nudge from behind just scrubs speed.
          speed = math.min(speed, v.speed * 0.85);
          z = v.z - reach;
          if (_bumpCooldown <= 0) {
            events.add(WorldEvent.bump);
            _bumpCooldown = 0.6;
          }
        } else {
          lastHit = '${v.kind.name} dz=${dz.toStringAsFixed(1)} '
              'dx=${dx.toStringAsFixed(2)} lane=${v.lane} dir=${v.dir} '
              'x=${x.toStringAsFixed(2)} v=${speed.toStringAsFixed(0)} '
              'vv=${v.speed.toStringAsFixed(0)}';
          hitProp = null;
          _crash();
        }
        v.ahead = v.z > z;
        continue;
      }

      final nowAhead = dz > 0;
      if (v.ahead && !nowAhead && !v.counted && crashTimer <= 0) {
        v.counted = true;
        if (!v.oncoming) {
          overtakes++;
          events.add(WorldEvent.overtake);
        }
        final gap = dx.abs() - wide;
        if (gap < 0.17 && speed > stats.topSpeed * 0.55 && invulnerable <= 0) {
          nearMisses++;
          combo++;
          bestCombo = math.max(bestCombo, combo);
          comboTimer = 3.5;
          bonus += (v.oncoming ? 40 : 20) * math.min(combo, 10);
          events.add(WorldEvent.nearMiss);
        }
      }
      v.ahead = nowAhead;
    }

    _hitRoadside();

    for (final r in racers) {
      final dz = r.z - z;
      final dx = r.x - x;
      if (dz.abs() < 1.9 && dx.abs() < 0.15 && crashTimer <= 0) {
        final push = (dx >= 0 ? -1 : 1) * 0.9 * dt;
        x += push;
        r.x -= push;
        if (dz > 0) {
          speed = math.min(speed, r.speed * 0.97);
        } else {
          r.speed = math.min(r.speed, speed * 0.97);
        }
        if (_bumpCooldown <= 0) {
          events.add(WorldEvent.bump);
          _bumpCooldown = 0.6;
        }
      }
    }
  }

  /// Trees, poles, stalls and house fronts are solid: riding into one off
  /// the tarmac is a crash, and the bike is thrown back onto the road.
  void _hitRoadside() {
    if (x.abs() <= 1 || crashTimer > 0 || invulnerable > 0) return;
    final here = (z / kSegmentLength).floor();
    final n = track.segments.length;
    for (var i = here - 1; i <= here + 1; i++) {
      final seg = track.segments[(i % n + n) % n];
      for (final item in seg.scenery) {
        final solid = propSolids[item.prop];
        if (solid == null) continue;
        final dz = (i + 0.5) * kSegmentLength - z;
        if (dz.abs() > solid.depth) continue;
        if ((item.x - x).abs() > solid.halfWidth + kRiderWidth / 2) continue;
        final side = x.sign;
        x = side * 0.8;
        if (speed < worldSpeed(10)) {
          // Walking pace: just bounced back, no fall.
          speed = 0;
          return;
        }
        hitProp = item.prop;
        lastHit = item.prop.name;
        _crash();
        return;
      }
    }
  }

  void _crash() {
    crashes++;
    combo = 0;
    comboTimer = 0;
    speed = 0;
    crashTimer = 1.8;
    invulnerable = 3.3;
    if (config.mode == RunMode.endless) lives--;
    events.add(WorldEvent.crash);
  }

  void _moveRacers(double dt) {
    for (final r in racers) {
      if (r.finishTime != null) {
        r.speed = math.max(r.stats.topSpeed * 0.5, r.speed - 12 * dt);
        r.z += r.speed * dt;
        continue;
      }
      // Rivals ease off a touch when well ahead and dig in when behind.
      final band = ((z - r.z) / 700).clamp(-0.07, 0.06);
      final curve = track.segmentAt(r.z).curve.abs();
      var target = r.stats.topSpeed * r.setup.skill * (1 + band) *
          (1 - 0.012 * curve);

      final plan = planLane(r.z, r.x, r.speed);
      r.lane = plan.lane;
      if (plan.limit != null) target = math.min(target, plan.limit!);

      r.speed += r.stats.accel * 1.15 * (target - r.speed) * dt;
      if (r.speed > target + 4) r.speed -= worldSpeed(50) * dt;
      r.speed = math.max(0, r.speed);

      final want = laneX(r.lane);
      final sp = r.speed / r.stats.topSpeed;
      final step = r.stats.handling * 0.9 * (0.3 + 0.7 * sp) * dt;
      final move = (want - r.x).clamp(-step, step).toDouble();
      r.steer += ((step == 0 ? 0 : move / step) - r.steer) *
          math.min(1, dt * 8);
      r.x += move;
      r.z += r.speed * dt;

      if (config.goalZ > 0 && r.z >= config.goalZ) r.finishTime = time;
    }
    // Keep rivals from riding through one another.
    for (var i = 0; i < racers.length; i++) {
      for (var j = i + 1; j < racers.length; j++) {
        final a = racers[i], b = racers[j];
        if ((a.z - b.z).abs() < 2.2 && (a.x - b.x).abs() < 0.16) {
          final push = (a.x >= b.x ? 1 : -1) * 0.5 * dt;
          a.x += push;
          b.x -= push;
        }
      }
    }
    position = 1 + racers.where((r) => r.finishTime != null || r.z > z).length;
  }

  /// Which lane a rider at ([atZ], [atX]) doing [atSpeed] should aim for,
  /// and a speed cap if there is no way round what is in front.
  ({int lane, double? limit}) planLane(double atZ, double atX, double atSpeed) {
    final look = 16 + atSpeed * 0.9;
    final mine = laneOf(atX);

    double? blockedBy(int lane) {
      // Returns the blocker's signed speed, or null if the lane is open.
      double? worst;
      var nearest = double.infinity;
      for (final v in traffic) {
        if (v.lane != lane) continue;
        final gap = v.z - atZ;
        final behind = -(v.spec.length / 2 + 4);
        final range = v.oncoming ? look * 3.2 : look + v.spec.length / 2;
        if (gap > behind && gap < range && gap < nearest) {
          nearest = gap;
          worst = v.speed * v.dir;
        }
      }
      return worst;
    }

    final here = blockedBy(mine);
    final oncomingHere = config.twoWay && mine < kLanes ~/ 2;
    if (here == null && !oncomingHere) return (lane: mine, limit: null);

    // An open lane next door, preferring the with-traffic side of the road.
    // Never two lanes over: that means riding through the one in between.
    final options = [mine + 1, mine - 1]
        .where((l) => l >= 0 && l < kLanes)
        .toList();
    for (final l in options) {
      if (config.twoWay && l < kLanes ~/ 2) continue;
      if (blockedBy(l) == null) return (lane: l, limit: null);
    }
    if (here == null) return (lane: mine, limit: null);
    for (final l in options) {
      if (blockedBy(l) == null) return (lane: l, limit: null);
    }
    if (here < 0) {
      // Head-on with nowhere clean to go: take any with-traffic lane.
      final escape = options.firstWhere(
        (l) => !config.twoWay || l >= kLanes ~/ 2,
        orElse: () => mine,
      );
      return (lane: escape, limit: blockedBy(escape)?.abs());
    }
    return (lane: mine, limit: here);
  }

  void _checkEnd() {
    switch (config.mode) {
      case RunMode.endless:
        if (lives <= 0) _finish(true);
      case RunMode.race:
        if (z >= config.goalZ) {
          position =
              1 + racers.where((r) => r.finishTime != null).length;
          _finish(position <= 3);
        }
      case RunMode.mission:
        final done = switch (config.goal) {
          GoalType.deliver => z >= config.goalZ,
          GoalType.overtake => overtakes >= config.goalCount,
          GoalType.nearMiss => nearMisses >= config.goalCount,
        };
        if (done) {
          _finish(true);
        } else if (config.maxCrashes >= 0 && crashes > config.maxCrashes) {
          failReason = 'Đổ hàng mất rồi!';
          _finish(false);
        } else if (config.timeLimit > 0 && time >= config.timeLimit) {
          failReason = 'Hết giờ!';
          _finish(false);
        }
    }
  }

  void _finish(bool ok) {
    success = ok;
    phase = Phase.finished;
    events.add(ok ? WorldEvent.finish : WorldEvent.fail);
  }
}

/// Rides the player's bike with the same lane sense the rivals have. Used
/// to check that stages and missions can be done, and for demo rides.
class Autopilot {
  const Autopilot({this.caution = 1.0});

  /// Above 1 brakes earlier.
  final double caution;

  Controls drive(World w) {
    final plan = w.planLane(w.z, w.x, w.speed);
    var want = laneX(plan.lane);
    // Pull out from behind a rival instead of sitting on their wheel.
    for (final r in w.racers) {
      final gap = r.z - w.z;
      if (gap > 0 && gap < 12 && (r.x - want).abs() < 0.2) {
        want += r.x > want ? -0.22 : 0.22;
        break;
      }
    }
    final steer = ((want - w.x) * 5).clamp(-1.0, 1.0).toDouble();
    final brake = plan.limit != null && w.speed > plan.limit! * caution;
    return Controls(steer: steer, brake: brake);
  }
}
