import 'package:flutter_test/flutter_test.dart';
import 'package:moto_xua/core/bikes.dart';
import 'package:moto_xua/core/cosmetics.dart';
import 'package:moto_xua/render/art_vehicles.dart';
import 'package:moto_xua/services/progress.dart';
import 'package:moto_xua/services/sound_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every bike has a free factory paint and the rest cost money', () {
    for (final b in BikeId.values) {
      final list = liveries[b]!;
      expect(list.length, greaterThanOrEqualTo(3), reason: b.name);
      expect(list.first.price, 0, reason: b.name);
      expect(list.skip(1).every((l) => l.price > 0), isTrue, reason: b.name);
    }
    // The player's look before 1.3 (hat 0, shirt 0) must stay free.
    expect(hats.first.price, 0);
    expect(shirts.first.price, 0);
  });

  test('hats, shirts and paint are bought once, worn, and saved', () async {
    SharedPreferences.setMockInitialValues({});
    final p = Progress.instance;
    await p.load();
    p.coins = 1000;
    final hat = hats.indexWhere((h) => h.price > 1000);
    expect(p.pickHat(hat), isFalse, reason: 'too dear');
    expect(p.hat, 0);
    expect(p.coins, 1000);

    p.coins = 20000;
    expect(p.pickHat(hat), isTrue);
    expect(p.coins, 20000 - hats[hat].price);
    expect(p.pickShirt(8), isTrue);
    expect(p.pickPaint(BikeId.cub, 2), isTrue);
    final left = p.coins;
    // Back to a free hat and then to the bought one: no second charge.
    expect(p.pickHat(0), isTrue);
    expect(p.pickHat(hat), isTrue);
    expect(p.coins, left);
    expect(p.look.hat, hat);
    expect(p.look.shirt, 8);
    expect(p.look.paint, 2);
    await Future<void>.delayed(Duration.zero);

    // Wipe memory and read it all back from the save.
    p.hat = 0;
    p.shirt = 0;
    p.boughtHats.clear();
    await p.load();
    expect(p.hat, hat);
    expect(p.shirt, 8);
    expect(p.paints[BikeId.cub], 2);
    expect(p.hasHat(hat), isTrue);
    expect(p.hasPaint(BikeId.cub, 3), isFalse);
  });

  test('a save from before 1.3 loads with the old look', () async {
    SharedPreferences.setMockInitialValues({
      'progress_v1': '{"coins":500,"owned":["cub"],"selected":"cub"}',
    });
    final p = Progress.instance;
    await p.load();
    expect(p.coins, 500);
    expect(p.look.hat, 0);
    expect(p.look.shirt, 0);
    expect(p.look.paint, 0);
  });

  test('every look draws, from behind and head-on', () {
    for (final b in BikeId.values) {
      for (var i = 0; i < liveries[b]!.length; i++) {
        buildRider(b, RiderLook(paint: i));
      }
    }
    for (var i = 0; i < hats.length; i++) {
      buildRider(BikeId.cub, RiderLook(hat: i), front: true);
    }
    for (var i = 0; i < shirts.length; i++) {
      buildRider(BikeId.x67, RiderLook(shirt: i));
    }
  });

  test('music has its own switch; an old mute keeps the music off', () async {
    SharedPreferences.setMockInitialValues({'sound_enabled': false});
    final s = SoundService.instance;
    final prefs = await SharedPreferences.getInstance();
    s.enabled.value = prefs.getBool('sound_enabled') ?? true;
    s.music.value = prefs.getBool('music_enabled') ?? s.enabled.value;
    expect(s.music.value, isFalse);

    s.enabled.value = true;
    s.music.value = true;
    await s.toggleMusic();
    expect(s.music.value, isFalse);
    expect(s.enabled.value, isTrue, reason: 'engine sound stays on');
    expect(prefs.getBool('music_enabled'), isFalse);
  });
}
