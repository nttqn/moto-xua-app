/// Race stages, missions and what they pay. Pure Dart.
library;

import 'bikes.dart';
import 'track.dart';
import 'world.dart';

class Stage {
  const Stage({
    required this.title,
    required this.theme,
    required this.km,
    required this.bike,
    required this.rivalLevel,
    required this.prize,
    this.curviness = 0.3,
    this.hilliness = 0.2,
    this.density = 1.8,
    this.twoWay = false,
    this.dusk = false,
    this.fast,
    this.skill = 0.86,
  });

  final String title;
  final ThemeId theme;
  final double km;

  /// What most of the field rides, and the bike the stage is tuned for.
  final BikeId bike;
  final int rivalLevel;
  final int prize;
  final double curviness;
  final double hilliness;
  final double density;
  final bool twoWay;
  final bool dusk;

  /// One rival on a quicker bike, to give the leader a fight.
  final BikeId? fast;

  /// Skill of the slowest rival; the quickest sits 0.08 above.
  final double skill;
}

const List<String> _riders = [
  'Tư Sẹo', 'Sáu Lửa', 'Út Rô', 'Hai Lúa', 'Tám Tàng',
  'Chín Ngón', 'Bảy Xị', 'Cô Ba', 'Thằng Tèo', 'Anh Tài',
];

const List<Stage> stages = [
  Stage(title: 'Vòng xoay Chợ Lớn', theme: ThemeId.saigon, km: 1.6,
      bike: BikeId.cub, rivalLevel: 0, prize: 400, curviness: 0.15,
      hilliness: 0, density: 1.5, skill: 0.80),
  Stage(title: 'Bờ Hồ sáng sớm', theme: ThemeId.hanoi, km: 1.8,
      bike: BikeId.cub, rivalLevel: 0, prize: 550, curviness: 0.3,
      hilliness: 0, density: 1.8, skill: 0.84),
  Stage(title: 'Quốc lộ 1 nắng gắt', theme: ThemeId.lua, km: 2.4,
      bike: BikeId.dd, rivalLevel: 0, fast: BikeId.wave, prize: 750, curviness: 0.3,
      hilliness: 0.25, density: 1.6, twoWay: true,
      skill: 0.84),
  Stage(title: 'Chiều cầu chữ Y', theme: ThemeId.saigon, km: 2.2,
      bike: BikeId.wave, rivalLevel: 0, prize: 1000, curviness: 0.35,
      hilliness: 0.35, density: 2.0, dusk: true, skill: 0.84),
  Stage(title: 'Miệt vườn Cái Bè', theme: ThemeId.mientay, km: 2.6,
      bike: BikeId.wave, rivalLevel: 1, fast: BikeId.simson, prize: 1250, curviness: 0.5,
      hilliness: 0.1, density: 1.8, twoWay: true, skill: 0.85),
  Stage(title: 'Đèo Hải Vân', theme: ThemeId.deo, km: 3.0,
      bike: BikeId.simson, rivalLevel: 0, fast: BikeId.dream, prize: 1600, curviness: 0.85,
      hilliness: 0.8, density: 1.3, twoWay: true,
      skill: 0.85),
  Stage(title: 'Phố cổ giờ tan tầm', theme: ThemeId.hanoi, km: 2.4,
      bike: BikeId.dream, rivalLevel: 0, prize: 2000, curviness: 0.4,
      hilliness: 0, density: 3.0, skill: 0.85),
  Stage(title: 'Xa lộ Biên Hòa', theme: ThemeId.lua, km: 3.6,
      bike: BikeId.dream, rivalLevel: 1, fast: BikeId.sport, prize: 2400, curviness: 0.2,
      hilliness: 0.2, density: 2.2, skill: 0.87),
  Stage(title: 'Đường đê sông Hậu', theme: ThemeId.mientay, km: 3.2,
      bike: BikeId.sport, rivalLevel: 0, prize: 2900, curviness: 0.6,
      hilliness: 0.15, density: 2.0, twoWay: true, dusk: true, skill: 0.87),
  Stage(title: 'Đèo Ngang mù sương', theme: ThemeId.deo, km: 3.6,
      bike: BikeId.sport, rivalLevel: 2, fast: BikeId.x67, prize: 3500, curviness: 0.9,
      hilliness: 0.9, density: 1.5, twoWay: true,
      skill: 0.87),
  Stage(title: 'Đêm hội Lê Lợi', theme: ThemeId.saigon, km: 3.0,
      bike: BikeId.x67, rivalLevel: 1, prize: 4500, curviness: 0.4,
      hilliness: 0.1, density: 3.0, dusk: true, skill: 0.87),
  Stage(title: 'Xuyên Việt', theme: ThemeId.lua, km: 5.0,
      bike: BikeId.x67, rivalLevel: 3, prize: 7000, curviness: 0.5,
      hilliness: 0.4, density: 2.2, twoWay: true, skill: 0.89),
];

RunConfig stageConfig(int index) {
  final s = stages[index];
  const field = 5;
  final rivals = <RivalSetup>[
    for (var i = 0; i < field; i++)
      RivalSetup(
        _riders[(index * 3 + i) % _riders.length],
        i == field - 1 && s.fast != null ? s.fast! : s.bike,
        level: i == field - 1 && s.fast != null ? 0 : s.rivalLevel,
        skill: s.skill + 0.02 * i,
      ),
  ];
  return RunConfig(
    mode: RunMode.race,
    theme: s.theme,
    seed: 1000 + index * 17,
    distanceKm: s.km,
    curviness: s.curviness,
    hilliness: s.hilliness,
    density: s.density,
    twoWay: s.twoWay,
    dusk: s.dusk,
    rivals: rivals,
  );
}

int racePrize(Stage s, int position) => switch (position) {
  1 => s.prize,
  2 => (s.prize * 0.6).round(),
  3 => (s.prize * 0.35).round(),
  _ => (s.prize * 0.08).round(),
};

int raceStars(int position) => position <= 3 ? 4 - position : 0;

class Mission {
  const Mission({
    required this.title,
    required this.brief,
    required this.theme,
    required this.goal,
    required this.bike,
    required this.reward,
    this.km = 0,
    this.count = 0,
    this.seconds = 0,
    this.pace = 0.72,
    this.maxCrashes = -1,
    this.density = 1.8,
    this.twoWay = false,
    this.dusk = false,
    this.curviness = 0.35,
    this.hilliness = 0.2,
  });

  final String title;
  final String brief;
  final ThemeId theme;
  final GoalType goal;

  /// The bike the clock is set for.
  final BikeId bike;
  final int reward;
  final double km;
  final int count;

  /// Fixed clock for counting goals.
  final double seconds;

  /// Deliveries: the clock allows this fraction of [bike]'s top speed on
  /// average over the distance.
  final double pace;
  final int maxCrashes;
  final double density;
  final bool twoWay;
  final bool dusk;
  final double curviness;
  final double hilliness;

  double get timeLimit => goal == GoalType.deliver
      ? km / (bikeSpec(bike).topKmh * pace) * 3600
      : seconds;

  String get goalText => switch (goal) {
    GoalType.deliver =>
      'Chạy ${km.toStringAsFixed(1)} km trong ${timeLimit.round()} giây',
    GoalType.overtake => 'Vượt $count xe trong ${seconds.round()} giây',
    GoalType.nearMiss =>
      'Lách sát $count xe trong ${seconds.round()} giây',
  };

  String get ruleText => switch (maxCrashes) {
    0 => 'Không được ngã lần nào',
    1 => 'Chỉ được ngã 1 lần',
    _ => '',
  };
}

const List<Mission> missions = [
  Mission(title: 'Giao báo buổi sáng',
      brief: 'Chồng báo còn thơm mùi mực phải tới sạp trước khi phố đông.',
      theme: ThemeId.hanoi, goal: GoalType.deliver, bike: BikeId.cub,
      reward: 300, km: 1.2, pace: 0.62, density: 1.4, curviness: 0.2,
      hilliness: 0),
  Mission(title: 'Phở nóng kẻo nguội',
      brief: 'Cà mèn phở tái cho ông chủ tiệm vàng. Nguội là ổng không trả tiền.',
      theme: ThemeId.saigon, goal: GoalType.deliver, bike: BikeId.cub,
      reward: 400, km: 1.6, pace: 0.68, density: 1.8, hilliness: 0.05),
  Mission(title: 'Qua mặt cả phố',
      brief: 'Trễ giờ làm rồi. Vượt hết đám xe đạp, xích lô trước mặt.',
      theme: ThemeId.saigon, goal: GoalType.overtake, bike: BikeId.cub,
      reward: 450, count: 25, seconds: 62, density: 2.4, hilliness: 0.05),
  Mission(title: 'Chở đá cây',
      brief: 'Cây đá cho quán chè đầu làng. Ngã một cái là vỡ sạch.',
      theme: ThemeId.lua, goal: GoalType.deliver, bike: BikeId.dd,
      reward: 600, km: 2.0, pace: 0.60, maxCrashes: 0, density: 1.5),
  Mission(title: 'Tay lái lụa',
      brief: 'Tụi nhỏ đầu ngõ cá là anh không dám lách sát. Cho tụi nó coi.',
      theme: ThemeId.hanoi, goal: GoalType.nearMiss, bike: BikeId.dd,
      reward: 650, count: 8, seconds: 120, density: 2.4, curviness: 0.2,
      hilliness: 0),
  Mission(title: 'Đón con tan trường',
      brief: 'Trống trường sắp điểm. Con bé đứng chờ ở cổng một mình.',
      theme: ThemeId.saigon, goal: GoalType.deliver, bike: BikeId.wave,
      reward: 800, km: 2.0, pace: 0.70, density: 2.4, dusk: true),
  Mission(title: 'Chở heo ra chợ',
      brief: 'Con heo trăm ký sau yên. Ngã hai lần là nó chạy mất.',
      theme: ThemeId.mientay, goal: GoalType.deliver, bike: BikeId.wave,
      reward: 1000, km: 2.4, pace: 0.66, maxCrashes: 1, twoWay: true,
      curviness: 0.5),
  Mission(title: 'Vượt đoàn xe quốc lộ',
      brief: 'Xe tải, xe đò nối đuôi nhau. Qua mặt được 40 chiếc mới kịp phà.',
      theme: ThemeId.lua, goal: GoalType.overtake, bike: BikeId.simson,
      reward: 1100, count: 40, seconds: 150, density: 2.6, twoWay: true),
  Mission(title: 'Hột vịt lộn',
      brief: 'Hai giỏ hột vịt lộn cho quán nhậu. Bể một trứng là đền cả giỏ.',
      theme: ThemeId.mientay, goal: GoalType.deliver, bike: BikeId.simson,
      reward: 1300, km: 2.5, pace: 0.64, maxCrashes: 0, density: 2.0,
      curviness: 0.5),
  Mission(title: 'Lạng lách Sài Gòn',
      brief: 'Mười lăm pha lách sát, không trầy một vết sơn.',
      theme: ThemeId.saigon, goal: GoalType.nearMiss, bike: BikeId.wave,
      reward: 1400, count: 15, seconds: 150, density: 2.8),
  Mission(title: 'Thư hỏa tốc qua đèo',
      brief: 'Điện tín khẩn phải qua bên kia đèo trước khi trời tối.',
      theme: ThemeId.deo, goal: GoalType.deliver, bike: BikeId.dream,
      reward: 1800, km: 3.0, pace: 0.68, density: 1.3, twoWay: true,
      curviness: 0.85, hilliness: 0.8),
  Mission(title: 'Bia hơi chiều thứ bảy',
      brief: 'Hai két bia chai cho quán đầu phố. Ngã là thành nước lã.',
      theme: ThemeId.hanoi, goal: GoalType.deliver, bike: BikeId.dream,
      reward: 2100, km: 2.5, pace: 0.62, maxCrashes: 0, density: 2.8,
      dusk: true, hilliness: 0),
  Mission(title: 'Vua vượt mặt',
      brief: 'Sáu chục xe trong một hơi ga.',
      theme: ThemeId.saigon, goal: GoalType.overtake, bike: BikeId.sport,
      reward: 2300, count: 60, seconds: 80, density: 3.0),
  Mission(title: 'Rước dâu kịp giờ lành',
      brief: 'Thầy coi giờ rồi. Trễ một khắc là hai họ nhìn nhau.',
      theme: ThemeId.mientay, goal: GoalType.deliver, bike: BikeId.sport,
      reward: 2700, km: 3.5, pace: 0.72, density: 2.0, twoWay: true,
      curviness: 0.55),
  Mission(title: 'Ngược dòng',
      brief: 'Hai mươi lăm pha lách sát trên đường hai chiều.',
      theme: ThemeId.lua, goal: GoalType.nearMiss, bike: BikeId.dream,
      reward: 3000, count: 25, seconds: 200, density: 2.6, twoWay: true),
  Mission(title: 'Chuyến hàng xuyên đèo',
      brief: 'Hàng gấp cho ghe ngoài cửa biển. Chỉ được ngã một lần.',
      theme: ThemeId.deo, goal: GoalType.deliver, bike: BikeId.x67,
      reward: 4000, km: 4.5, pace: 0.70, maxCrashes: 1, density: 1.5,
      twoWay: true, curviness: 0.9, hilliness: 0.9),
];

RunConfig missionConfig(int index) {
  final m = missions[index];
  return RunConfig(
    mode: RunMode.mission,
    theme: m.theme,
    seed: 5000 + index * 13,
    distanceKm: m.goal == GoalType.deliver ? m.km : 0,
    curviness: m.curviness,
    hilliness: m.hilliness,
    density: m.density,
    twoWay: m.twoWay,
    dusk: m.dusk,
    timeLimit: m.timeLimit,
    maxCrashes: m.maxCrashes,
    goal: m.goal,
    goalCount: m.count,
  );
}

/// 3 stars with a quarter of the clock to spare, 2 with a tenth.
int missionStars(double timeLeft, double timeLimit) {
  final spare = timeLimit <= 0 ? 0 : timeLeft / timeLimit;
  if (spare >= 0.25) return 3;
  if (spare >= 0.10) return 2;
  return 1;
}

RunConfig endlessConfig(ThemeId theme, {required bool twoWay, required int seed}) {
  return RunConfig(
    mode: RunMode.endless,
    theme: theme,
    seed: seed,
    curviness: 0.45,
    hilliness: theme == ThemeId.deo ? 0.8 : 0.25,
    density: 1.6,
    twoWay: twoWay,
    dusk: seed.isOdd,
  );
}

int endlessCoins(int score) => score ~/ 10;
