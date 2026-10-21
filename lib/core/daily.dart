/// Three small jobs a day, the same for everyone on the same date. Pure Dart.
library;

import 'dart:math' as math;

enum DailyKind {
  nearMiss,
  overtake,
  distance,
  boost,
  winRace,
  mission,
  endlessScore,
  rainKm,
  nightKm,
}

class DailyTask {
  const DailyTask(this.kind, this.target, this.reward);
  final DailyKind kind;
  final int target;
  final int reward;

  String get text => switch (kind) {
    DailyKind.nearMiss => 'Lách sát $target xe',
    DailyKind.overtake => 'Vượt $target xe',
    DailyKind.distance => 'Chạy tổng cộng $target km',
    DailyKind.boost => 'Vặn hết ga $target lần',
    DailyKind.winRace => target == 1
        ? 'Về nhất một chặng đua'
        : 'Về nhất $target chặng đua',
    DailyKind.mission => target == 1
        ? 'Làm xong một nhiệm vụ'
        : 'Làm xong $target nhiệm vụ',
    DailyKind.endlessScore => 'Đạt $target điểm trong một lượt chạy vô tận',
    DailyKind.rainKm => 'Chạy $target km dưới trời mưa',
    DailyKind.nightKm => 'Chạy $target km ban đêm',
  };

  /// A best-of goal: progress is the highest single ride, not a running
  /// total.
  bool get isBest => kind == DailyKind.endlessScore;
}

/// What one ride contributed, gathered when it ends.
class RideTally {
  const RideTally({
    this.nearMisses = 0,
    this.overtakes = 0,
    this.boosts = 0,
    this.km = 0,
    this.wonRace = false,
    this.missionDone = false,
    this.endlessScore = 0,
    this.rain = false,
    this.night = false,
  });

  final int nearMisses;
  final int overtakes;
  final int boosts;
  final double km;
  final bool wonRace;
  final bool missionDone;
  final int endlessScore;
  final bool rain;
  final bool night;

  /// How much this ride moves [task] along (for a best-of task, the value
  /// to compare against the best so far).
  int amountFor(DailyTask task) => switch (task.kind) {
    DailyKind.nearMiss => nearMisses,
    DailyKind.overtake => overtakes,
    DailyKind.distance => km.floor(),
    DailyKind.boost => boosts,
    DailyKind.winRace => wonRace ? 1 : 0,
    DailyKind.mission => missionDone ? 1 : 0,
    DailyKind.endlessScore => endlessScore,
    DailyKind.rainKm => rain ? km.floor() : 0,
    DailyKind.nightKm => night ? km.floor() : 0,
  };
}

/// Paid on top once all three are claimed.
const int dailyBonus = 1000;

const Map<DailyKind, List<(int, int)>> _options = {
  DailyKind.nearMiss: [(12, 400), (20, 600), (30, 900)],
  DailyKind.overtake: [(50, 400), (80, 600), (120, 900)],
  DailyKind.distance: [(4, 400), (7, 600), (10, 900)],
  DailyKind.boost: [(3, 400), (5, 600), (8, 800)],
  DailyKind.winRace: [(1, 600), (2, 1000)],
  DailyKind.mission: [(1, 500), (2, 900)],
  DailyKind.endlessScore: [(1500, 500), (2500, 800), (4000, 1100)],
  DailyKind.rainKm: [(2, 600), (3, 800)],
  DailyKind.nightKm: [(2, 600), (3, 800)],
};

/// The calendar date as a key, e.g. "2026-10-21".
String dayKey(DateTime t) =>
    '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

/// Today's three jobs: three different kinds, picked from the date alone.
List<DailyTask> dailyTasksFor(DateTime day) {
  final rng = math.Random(day.year * 10000 + day.month * 100 + day.day);
  final kinds = DailyKind.values.toList()..shuffle(rng);
  return [
    for (final kind in kinds.take(3))
      () {
        final options = _options[kind]!;
        final (target, reward) = options[rng.nextInt(options.length)];
        return DailyTask(kind, target, reward);
      }(),
  ];
}
