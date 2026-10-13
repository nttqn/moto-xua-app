// Dev-only entry point for store screenshots: opens one screen in a set
// state, chosen by the URL. Driven by tool/store_shots/store_shots.js.
//
//   flutter build web --release -t lib/shots.dart -o build/shots
//
// ?s=home | garage | stages | missions | ride
// ride: &stage=N | &mission=N | &theme=0..4&two=1&dusk=1   (endless if neither)
//       &bike=0..6 &skip=<seconds pre-rolled> &boost=1 &seed=N
import 'package:flutter/material.dart';

import 'core/bikes.dart';
import 'core/content.dart';
import 'core/track.dart';
import 'core/world.dart';
import 'services/progress.dart';
import 'ui/garage_screen.dart';
import 'ui/home_screen.dart';
import 'ui/lists.dart';
import 'ui/ride_screen.dart';
import 'ui/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final q = Uri.base.queryParameters;
  int arg(String k, [int d = 0]) => int.tryParse(q[k] ?? '') ?? d;

  // A save a good way into the game, so lists and garage look lived in.
  final p = Progress.instance;
  p.coins = 18650;
  p.bestScore = 6420;
  p.owned.addAll(BikeId.values);
  p.selected = BikeId.values[arg('bike') % BikeId.values.length];
  for (final b in BikeId.values) {
    p.parts[b]!
      ..[Part.engine] = 3
      ..[Part.exhaust] = 2
      ..[Part.tyres] = 4
      ..[Part.throttle] = 1;
  }
  const stageStars = [3, 3, 2, 3, 1, 2, 3, 1];
  for (var i = 0; i < stageStars.length; i++) {
    p.stageStars[i] = stageStars[i];
  }
  const missionStars = [3, 2, 3, 3, 1, 2];
  for (var i = 0; i < missionStars.length; i++) {
    p.missionStars[i] = missionStars[i];
  }

  final Widget screen;
  switch (q['s']) {
    case 'garage':
      screen = const GarageScreen();
    case 'stages':
      screen = const StagesScreen();
    case 'missions':
      screen = const MissionsScreen();
    case 'ride':
      final RunConfig config;
      final String title;
      int? stage, mission;
      if (q.containsKey('stage')) {
        stage = arg('stage');
        config = stageConfig(stage);
        title = stages[stage].title;
      } else if (q.containsKey('mission')) {
        mission = arg('mission');
        config = missionConfig(mission);
        title = missions[mission].title;
      } else {
        final theme = ThemeId.values[arg('theme') % ThemeId.values.length];
        final base =
            endlessConfig(theme, twoWay: arg('two') == 1, seed: arg('seed', 2));
        config = RunConfig(
          mode: RunMode.endless,
          theme: theme,
          seed: base.seed,
          curviness: base.curviness,
          hilliness: base.hilliness,
          density: 2.6,
          twoWay: base.twoWay,
          dusk: arg('dusk') == 1,
        );
        title = 'Chạy vô tận';
      }
      screen = RideScreen(
        config: config,
        title: title,
        stageIndex: stage,
        missionIndex: mission,
        demoPilot: const Autopilot(),
        demoSkip: arg('skip').toDouble(),
        demoBoost: arg('boost') == 1,
      );
    default:
      screen = const HomeScreen();
  }
  runApp(MaterialApp(
    title: 'Xe Xưa',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    home: screen,
  ));
}
