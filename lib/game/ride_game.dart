import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../core/bikes.dart';
import '../core/world.dart';
import '../render/road_renderer.dart';

/// Runs one ride: steps the [World] and paints it. All widgets (HUD,
/// buttons, dialogs) live in Flutter on top of this.
class RideGame extends Game {
  RideGame({
    required this.world,
    required BikeId bike,
    required this.onEvent,
    SpriteBank? bank,
  }) : renderer = RoadRenderer(bank ?? sharedBank)..playerBike = bike;

  /// Sprites are expensive to draw and identical between rides.
  static final SpriteBank sharedBank = SpriteBank();

  final World world;
  final RoadRenderer renderer;
  final void Function(WorldEvent event) onEvent;

  /// Bumped about ten times a second so the HUD can rebuild cheaply.
  final ValueNotifier<int> hudTick = ValueNotifier(0);

  /// -1, 0 or 1 from the touch zones or keyboard.
  double steerInput = 0;
  bool brakeInput = false;
  bool boostInput = false;

  /// Lets a test or a demo ride drive instead of the player.
  Autopilot? autopilot;

  double _clock = 0;
  double _sinceHud = 0;

  @override
  void update(double dt) {
    // A long frame must not teleport the bike through a bus.
    var left = dt.clamp(0, 0.1).toDouble();
    while (left > 0) {
      final step = left > 1 / 60 ? 1 / 60 : left;
      final controls = autopilot != null
          ? autopilot!.drive(world)
          : Controls(
              steer: steerInput,
              brake: brakeInput,
              boost: boostInput,
            );
      world.update(step, controls);
      renderer.skyline += world.track.segmentAt(world.z).curve *
          world.speed * step * 0.9;
      left -= step;
    }
    _clock += dt;
    if (world.events.isNotEmpty) {
      final events = List<WorldEvent>.of(world.events);
      world.events.clear();
      events.forEach(onEvent);
    }
    _sinceHud += dt;
    if (_sinceHud >= 0.1) {
      _sinceHud = 0;
      hudTick.value++;
    }
  }

  @override
  void render(Canvas canvas) {
    renderer.render(canvas, size.toSize(), world, _clock);
  }
}
