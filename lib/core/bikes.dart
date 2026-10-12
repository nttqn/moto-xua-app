/// The four bikes and their upgrade maths. Pure Dart, no Flutter imports.
library;

/// Speeds are shown to the player in km/h, but the world moves faster than
/// that so the road feels quick from a high chase camera.
const double kSpeedScale = 1.8;

/// World metres per second for a speed shown as [kmh].
double worldSpeed(double kmh) => kmh / 3.6 * kSpeedScale;

/// The km/h figure shown for a world speed.
double shownKmh(double world) => world * 3.6 / kSpeedScale;

enum BikeId { cub, wave, dream, x67 }

enum Part { engine, exhaust, tyres }

const int maxPartLevel = 5;

class BikeSpec {
  const BikeSpec({
    required this.id,
    required this.name,
    required this.nick,
    required this.blurb,
    required this.price,
    required this.topKmh,
    required this.accel,
    required this.handling,
    required this.grip,
    required this.upgradeBase,
  });

  final BikeId id;
  final String name;
  final String nick;
  final String blurb;
  final int price;

  /// Top speed shown on the clock, stock.
  final double topKmh;

  /// How quickly the bike closes on its top speed (1/s scale, higher = punchier).
  final double accel;

  /// Sideways speed at full lock, in road half-widths per second.
  final double handling;

  /// Resistance to being pushed wide in bends (1 = neutral).
  final double grip;

  /// Price of the first upgrade level of any part.
  final int upgradeBase;
}

const List<BikeSpec> bikes = [
  BikeSpec(
    id: BikeId.cub,
    name: 'Cub 81',
    nick: 'Cánh én',
    blurb: 'Nhỏ, lành, uống xăng như ngửi. Chậm mà lách đâu cũng lọt.',
    price: 0,
    topKmh: 72,
    accel: 0.34,
    handling: 1.75,
    grip: 1.10,
    upgradeBase: 300,
  ),
  BikeSpec(
    id: BikeId.wave,
    name: 'Wave Tàu',
    nick: 'Xe Tàu',
    blurb: 'Rẻ, bốc, kêu to. Vào cua hơi văng nhưng đề ba thì khỏi chê.',
    price: 4000,
    topKmh: 92,
    accel: 0.46,
    handling: 1.60,
    grip: 0.85,
    upgradeBase: 600,
  ),
  BikeSpec(
    id: BikeId.dream,
    name: 'Dream Thái',
    nick: 'Giấc mơ',
    blurb: 'Cả gia tài một thời. Êm, đầm, chạy đường nào cũng ngon.',
    price: 12000,
    topKmh: 110,
    accel: 0.42,
    handling: 1.70,
    grip: 1.15,
    upgradeBase: 1100,
  ),
  BikeSpec(
    id: BikeId.x67,
    name: 'Xe 67',
    nick: 'Huyền thoại',
    blurb: 'Máy đứng, pô nổ giòn. Nhanh nhất hội nhưng phải ghì mới chịu cua.',
    price: 28000,
    topKmh: 132,
    accel: 0.50,
    handling: 1.50,
    grip: 0.95,
    upgradeBase: 1800,
  ),
];

BikeSpec bikeSpec(BikeId id) => bikes[id.index];

/// What the simulation actually uses, after upgrades.
class BikeStats {
  const BikeStats({
    required this.topSpeed,
    required this.accel,
    required this.handling,
    required this.grip,
  });

  /// World metres per second.
  final double topSpeed;
  final double accel;
  final double handling;
  final double grip;

  double get topKmh => shownKmh(topSpeed);
}

/// Máy = top speed, Pô = pick-up, Lốp = steering and grip.
BikeStats statsFor(BikeSpec spec, [Map<Part, int> levels = const {}]) {
  final engine = levels[Part.engine] ?? 0;
  final exhaust = levels[Part.exhaust] ?? 0;
  final tyres = levels[Part.tyres] ?? 0;
  return BikeStats(
    topSpeed: worldSpeed(spec.topKmh * (1 + 0.04 * engine)),
    accel: spec.accel * (1 + 0.10 * exhaust),
    handling: spec.handling * (1 + 0.05 * tyres),
    grip: spec.grip * (1 + 0.08 * tyres),
  );
}

/// Stats with every part at the same level; used for rivals.
BikeStats statsAtLevel(BikeSpec spec, int level) => statsFor(spec, {
  Part.engine: level,
  Part.exhaust: level,
  Part.tyres: level,
});

/// Cost to take a part from [level] to [level] + 1.
int upgradeCost(BikeSpec spec, int level) => spec.upgradeBase * (level + 1);

const Map<Part, String> partNames = {
  Part.engine: 'Máy',
  Part.exhaust: 'Pô',
  Part.tyres: 'Lốp',
};

const Map<Part, String> partEffects = {
  Part.engine: 'Tốc độ tối đa',
  Part.exhaust: 'Độ bốc',
  Part.tyres: 'Bám đường, bẻ lái',
};
