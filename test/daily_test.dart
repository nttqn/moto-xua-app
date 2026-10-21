import 'package:flutter_test/flutter_test.dart';
import 'package:moto_xua/core/daily.dart';
import 'package:moto_xua/services/progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('each day has three different jobs, the same all day long', () {
    final morning = dailyTasksFor(DateTime(2026, 10, 21, 7));
    final night = dailyTasksFor(DateTime(2026, 10, 21, 23));
    expect(morning.length, 3);
    expect({for (final t in morning) t.kind}.length, 3);
    expect([for (final t in night) t.text], [for (final t in morning) t.text]);
    // Over a month the days are not all the same.
    final sets = {
      for (var d = 1; d <= 30; d++)
        dailyTasksFor(DateTime(2026, 11, d)).map((t) => t.text).join('|'),
    };
    expect(sets.length, greaterThan(20));
  });

  test('rides fill jobs; best-of jobs keep the best ride', () {
    SharedPreferences.setMockInitialValues({});
    final p = Progress.instance;
    var day = DateTime(2026, 10, 21, 9);
    p.clock = () => day;
    addTearDown(() => p.clock = DateTime.now);

    final tasks = p.dailyTasks;
    // A ride that does a bit of everything, many times over.
    const ride = RideTally(
      nearMisses: 40, overtakes: 150, boosts: 10, km: 12, wonRace: true,
      missionDone: true, endlessScore: 5000, rain: true, night: true,
    );
    final done = [
      ...p.recordDaily(ride),
      ...p.recordDaily(ride),
    ];
    expect(done.length, 3, reason: 'each job completes once');
    for (var i = 0; i < 3; i++) {
      expect(p.dailyProgress[i], tasks[i].target, reason: 'capped at target');
    }

    final before = p.coins;
    var paid = 0;
    for (var i = 0; i < 3; i++) {
      paid += p.claimDaily(i);
    }
    expect(p.claimDaily(0), 0, reason: 'no paying twice');
    expect(p.dailyBonusReady, isTrue);
    paid += p.claimDailyBonus();
    expect(p.coins, before + paid);
    expect(paid, tasks.fold<int>(0, (s, t) => s + t.reward) + dailyBonus);
    expect(p.dailyClaimable, 0);

    // Next morning: fresh jobs, nothing done.
    day = DateTime(2026, 10, 22, 6);
    expect(p.dailyTasks, isNotEmpty);
    expect(p.dailyProgress, [0, 0, 0]);
    expect(p.dailyClaimed, [false, false, false]);
    expect(p.dailyBonusClaimed, isFalse);
  });

  test('a score job counts the best single run, not the sum', () {
    const job = DailyTask(DailyKind.endlessScore, 2500, 800);
    expect(const RideTally(endlessScore: 1800).amountFor(job), 1800);
    const rainJob = DailyTask(DailyKind.rainKm, 2, 600);
    expect(const RideTally(km: 3.4).amountFor(rainJob), 0);
    expect(const RideTally(km: 3.4, rain: true).amountFor(rainJob), 3);
  });
}
