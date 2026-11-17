import 'bikes.dart';

/// What the player wears and what colour their bike is. Pure looks: none
/// of it changes how a bike rides.

class Cosmetic {
  const Cosmetic(this.name, this.price);
  final String name;

  /// Coins; 0 = owned from the start.
  final int price;
}

/// Headgear, by the index `_headgear` in art_vehicles.dart draws. The
/// first six are also what rivals and traffic wear.
const hats = [
  Cosmetic('Mũ cối', 0),
  Cosmetic('Mũ tai bèo', 600),
  Cosmetic('Để đầu trần', 0),
  Cosmetic('Mũ lưỡi trai', 0),
  Cosmetic('Mũ bảo hiểm', 900),
  Cosmetic('Nón lá', 1200),
  Cosmetic('Mũ phớt', 1800),
  Cosmetic('Mũ len', 1500),
  Cosmetic('Mũ bảo hiểm đỏ', 2500),
];

enum ShirtPattern { plain, plaid, stripes }

class Shirt extends Cosmetic {
  const Shirt(super.name, super.price, this.color,
      {this.pattern = ShirtPattern.plain, this.accent = 0});

  /// ARGB.
  final int color;
  final ShirtPattern pattern;

  /// ARGB of the checks or stripes.
  final int accent;
}

/// The first six are also what rivals and traffic wear.
const shirts = [
  Shirt('Sơ mi trắng', 0, 0xFFF4F1E8),
  Shirt('Áo đỏ', 0, 0xFFD9534F),
  Shirt('Áo xanh dương', 0, 0xFF3B6FB5),
  Shirt('Áo vàng', 400, 0xFFF0C24B),
  Shirt('Áo xanh lá', 400, 0xFF5BA36B),
  Shirt('Áo tím', 400, 0xFF8E5BA3),
  Shirt('Bà ba đen', 900, 0xFF2A2A2E),
  Shirt('Bà ba nâu', 900, 0xFF7A5434),
  Shirt('Sơ mi caro', 1600, 0xFFC0392B,
      pattern: ShirtPattern.plaid, accent: 0xFF2C3E50),
  Shirt('Áo sọc', 1600, 0xFFF4F1E8,
      pattern: ShirtPattern.stripes, accent: 0xFF1F4E8C),
  Shirt('Áo khoác da', 3000, 0xFF4A2E1E),
];

class Livery extends Cosmetic {
  const Livery(super.name, super.price, this.body, this.trim);

  /// ARGB.
  final int body;
  final int trim;
}

/// Paint jobs per bike; the first is the factory colour each bike is
/// bought in.
const Map<BikeId, List<Livery>> liveries = {
  BikeId.cub: [
    Livery('Xanh nhà máy', 0, 0xFF2F6FB0, 0xFFF2EFE6),
    Livery('Xanh ngọc', 800, 0xFF3E9C93, 0xFFF2EFE6),
    Livery('Đỏ đô', 800, 0xFF8E2230, 0xFFF2EFE6),
    Livery('Hồng phấn', 1500, 0xFFCF7F86, 0xFFF2EFE6),
  ],
  BikeId.dd: [
    Livery('Đỏ nhà máy', 0, 0xFFC8242B, 0xFFF2EFE6),
    Livery('Xanh rêu', 1000, 0xFF56704A, 0xFFF2EFE6),
    Livery('Vàng chanh', 1000, 0xFFE0B526, 0xFFF2EFE6),
    Livery('Đen bóng', 1800, 0xFF26262B, 0xFFC9CED2),
  ],
  BikeId.wave: [
    Livery('Đỏ tem vàng', 0, 0xFFC4262B, 0xFFF0C24B),
    Livery('Xanh tem trắng', 1200, 0xFF1F5FAF, 0xFFF2EFE6),
    Livery('Đen tem đỏ', 1200, 0xFF222226, 0xFFD6312B),
    Livery('Bạc tem xanh', 2000, 0xFFAEB4BA, 0xFF2F6FB0),
  ],
  BikeId.simson: [
    Livery('Xanh lính', 0, 0xFF2E7D4F, 0xFFB4BABD),
    Livery('Đỏ cờ', 1400, 0xFFB3261E, 0xFFB4BABD),
    Livery('Xanh trời', 1400, 0xFF4F8CC9, 0xFFE9E6DC),
    Livery('Cam', 2200, 0xFFD9772B, 0xFF2C2D31),
  ],
  BikeId.dream: [
    Livery('Nho chín', 0, 0xFF6B1F2A, 0xFFD9C7A0),
    Livery('Xanh biển', 1600, 0xFF2C5E8C, 0xFFD9C7A0),
    Livery('Đen nhung', 1600, 0xFF24232A, 0xFFD9C7A0),
    Livery('Xanh cốm', 2500, 0xFF7FA35A, 0xFFF2EFE6),
  ],
  BikeId.sport: [
    Livery('Xanh trắng', 0, 0xFF1C3F94, 0xFFF2F4F6),
    Livery('Đỏ trắng', 1800, 0xFFC0272D, 0xFFF2F4F6),
    Livery('Vàng đen', 1800, 0xFFE6B422, 0xFF1E1E22),
    Livery('Xanh lá', 2800, 0xFF2F9E44, 0xFFF2F4F6),
  ],
  BikeId.x67: [
    Livery('Đen tuyền', 0, 0xFF1E1E22, 0xFFC9CED2),
    Livery('Đỏ đô', 2000, 0xFF7E1F26, 0xFFC9CED2),
    Livery('Xanh ngọc', 2000, 0xFF2F7F86, 0xFFC9CED2),
    Livery('Vàng nghệ', 3000, 0xFFD69A22, 0xFFC9CED2),
  ],
};

/// How one rider looks: hat and shirt by index into [hats] / [shirts],
/// paint by index into that bike's [liveries].
class RiderLook {
  const RiderLook({this.hat = 0, this.shirt = 0, this.paint = 0});

  /// Rivals and traffic: one number picks a matching hat and shirt.
  factory RiderLook.npc(int v) => RiderLook(hat: v % 6, shirt: v % 6);

  final int hat;
  final int shirt;
  final int paint;

  /// Unique per look, for sprite caches.
  int get key => (hat * 32 + shirt) * 8 + paint;
}
