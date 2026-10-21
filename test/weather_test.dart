import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moto_xua/core/bikes.dart';
import 'package:moto_xua/core/content.dart';
import 'package:moto_xua/core/track.dart';
import 'package:moto_xua/core/world.dart';
import 'package:moto_xua/services/ads_service.dart';
import 'package:moto_xua/services/progress.dart';
import 'package:moto_xua/ui/ride_screen.dart';
import 'package:moto_xua/services/leaderboard_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _dt = 1 / 60;

RunConfig _bend({bool rain = false}) => RunConfig(
      mode: RunMode.mission,
      theme: ThemeId.lua,
      seed: 1,
      distanceKm: 50,
      density: 0.0001,
      curviness: 1,
      hilliness: 0,
      rain: rain,
    );

void main() {
  setUpAll(() => LeaderboardService.disabled = true);

  test('a wet road pushes the bike wider and stops it more slowly', () {
    final stats = statsFor(bikes.first);
    double drift(bool rain) {
      final w = World(_bend(rain: rain), stats)..traffic.clear();
      w.speed = stats.topSpeed;
      // Ride the first bend hands-off and measure how far it carries us.
      var most = 0.0;
      for (var i = 0; i < 60 * 12; i++) {
        w.update(_dt, const Controls());
        most = most > w.x.abs() ? most : w.x.abs();
        if (w.crashes > 0) break;
      }
      return most;
    }

    expect(drift(true), greaterThan(drift(false)));

    double stopping(bool rain) {
      final w = World(_bend(rain: rain), stats)..traffic.clear();
      w.speed = stats.topSpeed;
      var t = 0.0;
      while (w.speed > 0 && t < 10) {
        w.update(_dt, const Controls(brake: true));
        t += _dt;
      }
      return t;
    }

    expect(stopping(true), greaterThan(stopping(false)));
  });

  test('a finished endless run can be revived once with one life', () {
    final w = World(endlessConfig(ThemeId.saigon, twoWay: true, seed: 4),
        statsFor(bikes.first));
    var t = 0.0;
    while (w.phase != Phase.finished && t < 600) {
      w.update(_dt, const Controls());
      t += _dt;
    }
    expect(w.lives, 0);
    final score = w.score;
    w.revive();
    expect(w.phase, Phase.running);
    expect(w.lives, 1);
    expect(w.invulnerable, greaterThan(0));
    expect(w.score, score, reason: 'the score carries on');
    w.update(_dt, const Controls());
    expect(w.phase, Phase.running);
  });

  testWidgets('the revive offer appears, and watching it rides on',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    AdsService.instance.simulateRewarded = true;
    addTearDown(() => AdsService.instance.simulateRewarded = false);
    final config = RunConfig(
      mode: RunMode.endless,
      theme: ThemeId.saigon,
      seed: 4,
      density: 2.6,
      lives: 1,
    );
    await tester.pumpWidget(MaterialApp(
      home: RideScreen(config: config, title: 'Chạy vô tận'),
    ));
    // Hands off until the single life is gone and the offer comes up.
    for (var i = 0; i < 400 && find.text('HẾT MẠNG').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(find.text('HẾT MẠNG'), findsOneWidget);
    final coins = Progress.instance.coins;
    await tester.tap(find.text('CHẠY TIẾP'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('HẾT MẠNG'), findsNothing);
    expect(Progress.instance.coins, coins, reason: 'nothing paid yet');
    // The second fall goes straight to the results; doubling is offered.
    for (var i = 0; i < 400 && find.text('NHÂN ĐÔI TIỀN').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(find.text('NHÂN ĐÔI TIỀN'), findsOneWidget);
    final paid = Progress.instance.coins;
    await tester.tap(find.text('NHÂN ĐÔI TIỀN'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(Progress.instance.coins, greaterThan(paid));
    expect(find.text('NHÂN ĐÔI TIỀN'), findsNothing);
  });
}
