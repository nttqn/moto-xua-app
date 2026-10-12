import 'package:flutter/material.dart';

import '../core/bikes.dart';
import '../game/ride_game.dart';
import '../services/progress.dart';
import 'theme.dart';

class GarageScreen extends StatefulWidget {
  const GarageScreen({super.key});

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  late final PageController _pages = PageController(
    initialPage: Progress.instance.selected.index,
    viewportFraction: 0.9,
  );

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GARA'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 10),
            child: Center(child: CoinChip()),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Progress.instance,
        builder: (context, _) => PageView(
          controller: _pages,
          children: [for (final spec in bikes) _BikeCard(spec)],
        ),
      ),
    );
  }
}

class _BikeCard extends StatelessWidget {
  const _BikeCard(this.spec);
  final BikeSpec spec;

  @override
  Widget build(BuildContext context) {
    final progress = Progress.instance;
    final owned = progress.owned.contains(spec.id);
    final selected = progress.selected == spec.id;
    final levels = progress.parts[spec.id]!;
    final stats = statsFor(spec, levels);
    final best = statsAtLevel(bikes.last, maxPartLevel);
    final sprite = RideGame.sharedBank.rider(spec.id, 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(6, 14, 6, 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? signTeal : ink.withValues(alpha: 0.35),
            width: selected ? 3 : 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 190,
              decoration: BoxDecoration(
                color: paperDark,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(10),
              child: RawImage(image: sprite.image, fit: BoxFit.contain),
            ),
            const SizedBox(height: 12),
            Text(spec.name,
                textAlign: TextAlign.center,
                style: signText.copyWith(fontSize: 26, color: signRed)),
            Text('“${spec.nick}”',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(spec.blurb, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            _bar('Tốc độ', stats.topSpeed / best.topSpeed,
                '${stats.topKmh.round()} km/h'),
            _bar('Độ bốc', stats.accel / 0.8, ''),
            _bar('Bẻ lái', stats.handling / 2.3, ''),
            _bar('Bám đường', stats.grip / 1.7, ''),
            const SizedBox(height: 10),
            if (!owned)
              SignButton(
                label: 'MUA  ${money(spec.price)}',
                color: signTeal,
                onTap: progress.coins >= spec.price
                    ? () => progress.buy(spec.id)
                    : null,
                sub: progress.coins >= spec.price
                    ? null
                    : 'Còn thiếu ${money(spec.price - progress.coins)}',
              )
            else ...[
              SignButton(
                label: selected ? 'ĐANG ĐI' : 'LẤY XE NÀY',
                color: selected ? ink : signTeal,
                onTap: selected ? null : () => progress.select(spec.id),
              ),
              const SizedBox(height: 14),
              Text('ĐỘ XE',
                  style: signText.copyWith(fontSize: 16, color: ink)),
              for (final part in Part.values) _upgradeRow(part, levels[part]!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bar(String label, double value, String note) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        SizedBox(
          width: 82,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: value.clamp(0, 1).toDouble(),
              minHeight: 10,
              backgroundColor: ink.withValues(alpha: 0.15),
              color: signRed,
            ),
          ),
        ),
        if (note.isNotEmpty)
          SizedBox(
            width: 74,
            child: Text(note,
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
      ],
    ),
  );

  Widget _upgradeRow(Part part, int level) {
    final progress = Progress.instance;
    final maxed = level >= maxPartLevel;
    final cost = upgradeCost(spec, level);
    final can = !maxed && progress.coins >= cost;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${partNames[part]} · ${partEffects[part]}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    for (var i = 0; i < maxPartLevel; i++)
                      Container(
                        width: 20,
                        height: 8,
                        margin: const EdgeInsets.only(right: 3),
                        decoration: BoxDecoration(
                          color: i < level
                              ? signTeal
                              : ink.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            width: 124,
            child: SignButton(
              label: maxed ? 'HẾT CỠ' : money(cost),
              fontSize: 14,
              color: signBlue,
              onTap: can ? () => progress.upgrade(spec.id, part) : null,
            ),
          ),
        ],
      ),
    );
  }
}
