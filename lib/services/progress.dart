import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/bikes.dart';
import '../core/content.dart';
import 'sound_service.dart';

/// Everything the player keeps between sessions: money, bikes, stars.
class Progress extends ChangeNotifier {
  Progress._();
  static final Progress instance = Progress._();

  static const _key = 'progress_v1';

  int coins = 0;
  BikeId selected = BikeId.cub;
  final Set<BikeId> owned = {BikeId.cub};
  final Map<BikeId, Map<Part, int>> parts = {
    for (final b in BikeId.values) b: {for (final p in Part.values) p: 0},
  };
  final List<int> stageStars = List.filled(stages.length, 0);
  final List<int> missionStars = List.filled(missions.length, 0);
  int bestScore = 0;

  BikeStats get stats => statsFor(bikeSpec(selected), parts[selected]!);

  bool stageUnlocked(int i) => i == 0 || stageStars[i - 1] > 0;
  bool missionUnlocked(int i) => i == 0 || missionStars[i - 1] > 0;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      final m = jsonDecode(raw) as Map<String, dynamic>;
      coins = m['coins'] as int? ?? 0;
      bestScore = m['best'] as int? ?? 0;
      owned
        ..clear()
        ..add(BikeId.cub)
        ..addAll(_ids(m['owned']));
      final sel = _ids([m['selected']]);
      selected = sel.isNotEmpty && owned.contains(sel.first)
          ? sel.first
          : BikeId.cub;
      final savedParts = m['parts'] as Map<String, dynamic>? ?? {};
      for (final b in BikeId.values) {
        final levels = savedParts[b.name] as Map<String, dynamic>? ?? {};
        for (final p in Part.values) {
          parts[b]![p] =
              ((levels[p.name] as int?) ?? 0).clamp(0, maxPartLevel).toInt();
        }
      }
      _fill(stageStars, m['stages']);
      _fill(missionStars, m['missions']);
    } catch (_) {
      // A corrupt save just means starting over.
    }
    notifyListeners();
  }

  static Iterable<BikeId> _ids(Object? names) sync* {
    if (names is! List) return;
    for (final n in names) {
      for (final b in BikeId.values) {
        if (b.name == n) yield b;
      }
    }
  }

  static void _fill(List<int> into, Object? from) {
    if (from is! List) return;
    for (var i = 0; i < into.length && i < from.length; i++) {
      into[i] = (from[i] as int? ?? 0).clamp(0, 3).toInt();
    }
  }

  Future<void> _save() async {
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode({
          'coins': coins,
          'best': bestScore,
          'owned': [for (final b in owned) b.name],
          'selected': selected.name,
          'parts': {
            for (final b in BikeId.values)
              b.name: {for (final p in Part.values) p.name: parts[b]![p]},
          },
          'stages': stageStars,
          'missions': missionStars,
        }),
      );
    } catch (_) {}
  }

  bool buy(BikeId id) {
    final price = bikeSpec(id).price;
    if (owned.contains(id) || coins < price) return false;
    coins -= price;
    owned.add(id);
    selected = id;
    SoundService.instance.play(Sfx.coin);
    _save();
    return true;
  }

  void select(BikeId id) {
    if (!owned.contains(id)) return;
    selected = id;
    _save();
  }

  bool upgrade(BikeId id, Part part) {
    final level = parts[id]![part]!;
    final cost = upgradeCost(bikeSpec(id), level);
    if (!owned.contains(id) || level >= maxPartLevel || coins < cost) {
      return false;
    }
    coins -= cost;
    parts[id]![part] = level + 1;
    SoundService.instance.play(Sfx.coin);
    _save();
    return true;
  }

  /// Returns the prize paid.
  int recordStage(int index, int position) {
    final prize = racePrize(stages[index], position);
    stageStars[index] = math.max(stageStars[index], raceStars(position));
    coins += prize;
    _save();
    return prize;
  }

  /// Full pay the first time a mission is done, a quarter for repeats.
  int recordMission(int index, int stars) {
    final first = missionStars[index] == 0;
    final pay = first
        ? missions[index].reward
        : (missions[index].reward * 0.25).round();
    missionStars[index] = math.max(missionStars[index], stars);
    coins += pay;
    _save();
    return pay;
  }

  /// Returns the coins paid; [bestScore] is updated if beaten.
  int recordEndless(int score) {
    final pay = endlessCoins(score);
    bestScore = math.max(bestScore, score);
    coins += pay;
    _save();
    return pay;
  }
}
