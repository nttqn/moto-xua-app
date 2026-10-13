// Dev-only entry point: an autopilot ride with no menus, for eyeballing
// the renderer. `flutter build web -t lib/showcase.dart`, then open with
// ?theme=0..4&bike=0..3&two=1&dusk=1&race=1&boost=1&skip=<seconds to pre-roll>.
import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'core/bikes.dart';
import 'core/content.dart';
import 'core/track.dart';
import 'core/world.dart';
import 'game/ride_game.dart';

void main() {
  final q = Uri.base.queryParameters;
  int arg(String k, [int d = 0]) => int.tryParse(q[k] ?? '') ?? d;
  final theme = ThemeId.values[arg('theme') % ThemeId.values.length];
  final bike = BikeId.values[arg('bike') % BikeId.values.length];
  final RunConfig config;
  if (arg('race') == 1) {
    config = stageConfig(arg('stage'));
  } else {
    final base = endlessConfig(theme, twoWay: arg('two') == 1, seed: 2);
    config = RunConfig(
      mode: RunMode.endless,
      theme: theme,
      seed: arg('seed', 2),
      curviness: base.curviness,
      hilliness: base.hilliness,
      density: 2.4,
      twoWay: base.twoWay,
      dusk: arg('dusk') == 1,
      lives: 99,
    );
  }
  final world = World(config, statsFor(bikeSpec(bike)));
  const pilot = Autopilot();
  final skip = arg('skip');
  for (var i = 0; i < skip * 60; i++) {
    world.update(1 / 60, pilot.drive(world));
  }
  if (arg('boost') == 1) {
    // Hold the burst on so its effects are always on show.
    Timer.periodic(const Duration(milliseconds: 300), (_) {
      world.boostTimer = world.stats.boostTime;
    });
  }
  final game = RideGame(world: world, bike: bike, onEvent: (_) {})
    ..autopilot = pilot;
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(body: GameWidget(game: game)),
  ));
}
