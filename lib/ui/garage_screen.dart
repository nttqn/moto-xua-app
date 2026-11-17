import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/bikes.dart';
import '../core/cosmetics.dart';
import '../render/art_garage.dart';
import '../render/art_vehicles.dart';
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('GARA'),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 10),
              child: Center(child: CoinChip()),
            ),
          ],
          bottom: TabBar(
            indicatorColor: signYellow,
            indicatorWeight: 4,
            labelColor: const Color(0xFFFFF3C4),
            unselectedLabelColor:
                const Color(0xFFFFF3C4).withValues(alpha: 0.6),
            labelStyle: signText.copyWith(fontSize: 15),
            tabs: const [
              Tab(text: 'XE MÁY'),
              Tab(text: 'NGƯỜI LÁI'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListenableBuilder(
              listenable: Progress.instance,
              builder: (context, _) => PageView(
                controller: _pages,
                children: [for (final spec in bikes) _BikeCard(spec)],
              ),
            ),
            const _RiderTab(),
          ],
        ),
      ),
    );
  }
}

/// The buy button under a try-on: what it is, what it costs.
Widget _buyButton(String name, int price, VoidCallback onBuy) {
  final coins = Progress.instance.coins;
  return SignButton(
    label: 'MUA  ${money(price)}',
    sub: coins >= price ? name : '$name · còn thiếu ${money(price - coins)}',
    color: signTeal,
    fontSize: 18,
    onTap: coins >= price ? onBuy : null,
  );
}

class _BikeCard extends StatefulWidget {
  const _BikeCard(this.spec);
  final BikeSpec spec;

  @override
  State<_BikeCard> createState() => _BikeCardState();
}

class _BikeCardState extends State<_BikeCard> {
  /// A paint job being looked at but not bought (or not yet usable).
  int? _trying;

  BikeSpec get spec => widget.spec;

  @override
  Widget build(BuildContext context) {
    final progress = Progress.instance;
    final owned = progress.owned.contains(spec.id);
    final selected = progress.selected == spec.id;
    final levels = progress.parts[spec.id]!;
    final stats = statsFor(spec, levels);
    final best = statsAtLevel(bikes.last, maxPartLevel);
    final paint = _trying ?? progress.paints[spec.id]!;
    final trying = _trying;

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
              child: BikeSideView(spec.id, paint: paint),
            ),
            const SizedBox(height: 10),
            _paintRow(owned),
            if (owned && trying != null) ...[
              const SizedBox(height: 8),
              _buyButton(
                'Sơn ${liveries[spec.id]![trying].name}',
                liveries[spec.id]![trying].price,
                () {
                  if (progress.pickPaint(spec.id, trying)) {
                    setState(() => _trying = null);
                  }
                },
              ),
            ],
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
                    ? () {
                        setState(() => _trying = null);
                        progress.buy(spec.id);
                      }
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

  /// Paint swatches. Bought ones apply at once; others are tried on and
  /// bought with the button below. Only an owned bike can be painted, but
  /// any colour can be looked at.
  Widget _paintRow(bool owned) {
    final progress = Progress.instance;
    final list = liveries[spec.id]!;
    final current = progress.paints[spec.id]!;
    final shown = _trying ?? current;
    return Column(
      children: [
        Text(
          'MÀU SƠN · ${list[shown].name.toUpperCase()}',
          textAlign: TextAlign.center,
          style: signText.copyWith(fontSize: 13, color: ink),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < list.length; i++)
              _Swatch(
                body: Color(list[i].body),
                trim: Color(list[i].trim),
                active: i == shown,
                locked: !progress.hasPaint(spec.id, i),
                onTap: () {
                  if (owned && progress.hasPaint(spec.id, i)) {
                    progress.pickPaint(spec.id, i);
                    setState(() => _trying = null);
                  } else {
                    setState(() => _trying = i == current ? null : i);
                  }
                },
              ),
          ],
        ),
        if (!owned && _trying != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Mua xe rồi mới sơn được màu này',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: ink.withValues(alpha: 0.7)),
            ),
          ),
      ],
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

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.body,
    required this.trim,
    required this.active,
    required this.locked,
    required this.onTap,
  });

  final Color body;
  final Color trim;
  final bool active;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: active ? signRed : ink.withValues(alpha: 0.25),
            width: active ? 3 : 1.5,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [body, body, trim, trim],
                  stops: const [0, 0.62, 0.62, 1],
                ),
              ),
            ),
            if (locked)
              const Center(
                child: Icon(Icons.lock_rounded,
                    size: 18,
                    color: Color(0xEEFFFFFF),
                    shadows: [Shadow(blurRadius: 3)]),
              ),
          ],
        ),
      ),
    );
  }
}

/// Hat and shirt pickers with a live preview of the rider on the bike in
/// use, from behind (as in a ride) and head-on.
class _RiderTab extends StatefulWidget {
  const _RiderTab();

  @override
  State<_RiderTab> createState() => _RiderTabState();
}

class _RiderTabState extends State<_RiderTab> {
  int? _tryHat;
  int? _tryShirt;
  final Map<int, ui.Image> _images = {};

  ui.Image _image(BikeId bike, RiderLook look, bool front) {
    final key = (bike.index * 100000 + look.key) * 2 + (front ? 1 : 0);
    return _images[key] ??= buildRider(bike, look, front: front).image;
  }

  @override
  void dispose() {
    for (final img in _images.values) {
      img.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Progress.instance,
      builder: (context, _) {
        final progress = Progress.instance;
        final bike = progress.selected;
        final look = RiderLook(
          hat: _tryHat ?? progress.hat,
          shirt: _tryShirt ?? progress.shirt,
          paint: progress.paints[bike]!,
        );
        final tryHat = _tryHat, tryShirt = _tryShirt;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: paperDark,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  for (final front in [false, true])
                    Expanded(
                      child: RawImage(
                        image: _image(bike, look, front),
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (tryHat != null)
              _buyButton(hats[tryHat].name, hats[tryHat].price, () {
                if (progress.pickHat(tryHat)) setState(() => _tryHat = null);
              })
            else if (tryShirt != null)
              _buyButton(shirts[tryShirt].name, shirts[tryShirt].price, () {
                if (progress.pickShirt(tryShirt)) {
                  setState(() => _tryShirt = null);
                }
              })
            else
              Text(
                'Chạm để mặc thử. Đồ đã có thì mặc luôn.',
                textAlign: TextAlign.center,
                style: TextStyle(color: ink.withValues(alpha: 0.7)),
              ),
            const SizedBox(height: 16),
            Text('MŨ NÓN', style: signText.copyWith(fontSize: 16, color: ink)),
            const SizedBox(height: 8),
            _grid([
              for (var i = 0; i < hats.length; i++)
                _ItemTile(
                  name: hats[i].name,
                  price: hats[i].price,
                  owned: progress.hasHat(i),
                  worn: progress.hat == i,
                  active: look.hat == i,
                  icon: (c) => paintHatIcon(c, i),
                  onTap: () => setState(() {
                    _tryShirt = null;
                    if (progress.hasHat(i)) {
                      progress.pickHat(i);
                      _tryHat = null;
                    } else {
                      _tryHat = i;
                    }
                  }),
                ),
            ]),
            const SizedBox(height: 16),
            Text('ÁO', style: signText.copyWith(fontSize: 16, color: ink)),
            const SizedBox(height: 8),
            _grid([
              for (var i = 0; i < shirts.length; i++)
                _ItemTile(
                  name: shirts[i].name,
                  price: shirts[i].price,
                  owned: progress.hasShirt(i),
                  worn: progress.shirt == i,
                  active: look.shirt == i,
                  icon: (c) => paintShirtIcon(c, shirts[i]),
                  onTap: () => setState(() {
                    _tryHat = null;
                    if (progress.hasShirt(i)) {
                      progress.pickShirt(i);
                      _tryShirt = null;
                    } else {
                      _tryShirt = i;
                    }
                  }),
                ),
            ]),
            const SizedBox(height: 12),
            Text(
              'Màu sơn xe chọn ở thẻ XE MÁY.',
              textAlign: TextAlign.center,
              style: TextStyle(color: ink.withValues(alpha: 0.7)),
            ),
          ],
        );
      },
    );
  }

  Widget _grid(List<Widget> tiles) => LayoutBuilder(
    builder: (context, box) {
      const gap = 8.0;
      final cols = box.maxWidth >= 520 ? 5 : 3;
      final w = (box.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [for (final t in tiles) SizedBox(width: w, child: t)],
      );
    },
  );
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.name,
    required this.price,
    required this.owned,
    required this.worn,
    required this.active,
    required this.icon,
    required this.onTap,
  });

  final String name;
  final int price;
  final bool owned;
  final bool worn;

  /// In the preview right now (worn, or being tried on).
  final bool active;
  final void Function(Canvas c) icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.75),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? signRed : ink.withValues(alpha: 0.25),
              width: active ? 2.5 : 1.2,
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                width: 54,
                height: 54,
                child: CustomPaint(painter: _IconPainter(icon)),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
              const SizedBox(height: 2),
              SizedBox(
                height: 16,
                child: worn
                    ? const Text('ĐANG DÙNG',
                        style: TextStyle(
                            color: signTeal,
                            fontWeight: FontWeight.w800,
                            fontSize: 11))
                    : owned
                        ? Icon(Icons.check_circle_rounded,
                            size: 15, color: signTeal.withValues(alpha: 0.8))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.lock_rounded,
                                  size: 12, color: ink),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(money(price),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11)),
                              ),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconPainter extends CustomPainter {
  _IconPainter(this.draw);
  final void Function(Canvas c) draw;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 30, size.height / 30);
    draw(canvas);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IconPainter old) => true;
}
