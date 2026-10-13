import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/bikes.dart';
import '../core/content.dart';
import '../core/track.dart';
import '../core/world.dart';
import '../game/ride_game.dart';
import '../services/ads_service.dart';
import '../services/progress.dart';
import '../services/sound_service.dart';
import 'garage_screen.dart';
import 'lists.dart';
import 'ride_screen.dart';
import 'theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late RideGame _demo;
  BannerAd? _banner;
  bool _bannerLoaded = false;

  @override
  void initState() {
    super.initState();
    _demo = _newDemo();
    // The ads SDK starts up in the background; ask for a banner once it is
    // ready, or straight away if it already is.
    AdsService.instance.ready.addListener(_loadBanner);
    _loadBanner();
  }

  void _loadBanner() {
    if (_banner != null || !AdsService.instance.ready.value) return;
    _banner = AdsService.instance.createBannerAd(
      onLoaded: () {
        if (mounted) setState(() => _bannerLoaded = true);
      },
    );
  }

  @override
  void dispose() {
    AdsService.instance.ready.removeListener(_loadBanner);
    _banner?.dispose();
    super.dispose();
  }

  /// A ride nobody is playing, rolling behind the menu.
  RideGame _newDemo() {
    final rng = math.Random();
    final theme = ThemeId.values[rng.nextInt(ThemeId.values.length)];
    final base = endlessConfig(theme, twoWay: false, seed: rng.nextInt(1000));
    final config = RunConfig(
      mode: RunMode.endless,
      theme: theme,
      seed: base.seed,
      curviness: base.curviness,
      hilliness: base.hilliness,
      density: 2.2,
      dusk: base.dusk,
      lives: 1 << 30,
    );
    final bike = Progress.instance.selected;
    return RideGame(
      world: World(config, statsFor(bikeSpec(bike))),
      bike: bike,
      onEvent: (_) {},
    )..autopilot = const Autopilot();
  }

  Future<void> _open(Widget screen) async {
    _demo.pauseEngine();
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));
    if (!mounted) return;
    setState(() => _demo = _newDemo());
  }

  Future<void> _endless() async {
    final config = await showModalBottomSheet<RunConfig>(
      context: context,
      backgroundColor: paper,
      isScrollControlled: true,
      builder: (_) => const _EndlessSheet(),
    );
    if (config == null || !mounted) return;
    await _open(RideScreen(
      config: config,
      title: 'Chạy vô tận · ${themeNames[config.theme]}',
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(child: GameWidget(key: ValueKey(_demo), game: _demo)),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.35),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.55),
                ],
                stops: const [0, 0.4, 1],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ValueListenableBuilder<bool>(
                        valueListenable: SoundService.instance.enabled,
                        builder: (context, on, _) => IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: ink.withValues(alpha: 0.85),
                            foregroundColor: signYellow,
                          ),
                          tooltip: on ? 'Tắt tiếng' : 'Bật tiếng',
                          onPressed: SoundService.instance.toggle,
                          icon: Icon(on
                              ? Icons.volume_up_rounded
                              : Icons.volume_off_rounded),
                        ),
                      ),
                      const CoinChip(),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const _Title(),
                  const Spacer(),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SignButton(
                          label: 'CHẠY VÔ TẬN',
                          icon: Icons.all_inclusive_rounded,
                          onTap: _endless,
                        ),
                        const SizedBox(height: 10),
                        SignButton(
                          label: 'ĐUA CHẶNG',
                          icon: Icons.flag_rounded,
                          color: signBlue,
                          onTap: () => _open(const StagesScreen()),
                        ),
                        const SizedBox(height: 10),
                        SignButton(
                          label: 'NHIỆM VỤ',
                          icon: Icons.inventory_2_rounded,
                          color: signTeal,
                          onTap: () => _open(const MissionsScreen()),
                        ),
                        const SizedBox(height: 10),
                        SignButton(
                          label: 'GARA',
                          icon: Icons.build_rounded,
                          color: signYellow,
                          textColor: ink,
                          onTap: () => _open(const GarageScreen()),
                        ),
                      ],
                    ),
                  ),
                  if (_bannerLoaded && _banner != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: SizedBox(
                        width: _banner!.size.width.toDouble(),
                        height: _banner!.size.height.toDouble(),
                        child: AdWidget(ad: _banner!),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    Widget layer(Paint? stroke, Color? fill) => Text(
      'XE XƯA',
      style: signText.copyWith(
        fontSize: 64,
        color: fill,
        foreground: stroke,
        letterSpacing: 2,
      ),
    );
    return Column(
      children: [
        Stack(
          children: [
            layer(
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 10
                ..strokeJoin = StrokeJoin.round
                ..color = const Color(0xFF2A1A12),
              null,
            ),
            layer(null, signYellow),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: signRed,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF2A1A12), width: 2),
          ),
          child: const Text(
            'ĐUA XE MÁY MỘT THỜI',
            style: TextStyle(
              color: Color(0xFFFFF3C4),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _EndlessSheet extends StatefulWidget {
  const _EndlessSheet();

  @override
  State<_EndlessSheet> createState() => _EndlessSheetState();
}

class _EndlessSheetState extends State<_EndlessSheet> {
  ThemeId _theme = ThemeId.saigon;
  bool _twoWay = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('CHẠY VÔ TẬN',
                textAlign: TextAlign.center,
                style: signText.copyWith(fontSize: 22, color: signRed)),
            const SizedBox(height: 4),
            Text(
              'Ba mạng. Chạy càng xa, lách càng sát, điểm càng cao.\n'
              'Kỷ lục: ${Progress.instance.bestScore}  ·  ${bikeLine()}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final t in ThemeId.values)
                  ChoiceChip(
                    label: Text(themeNames[t]!),
                    selected: _theme == t,
                    onSelected: (_) => setState(() => _theme = t),
                  ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Đường hai chiều',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Lấn sang làn ngược chiều được thêm điểm'),
              value: _twoWay,
              onChanged: (v) => setState(() => _twoWay = v),
            ),
            const SizedBox(height: 6),
            SignButton(
              label: 'NỔ MÁY',
              color: signTeal,
              onTap: () => Navigator.of(context).pop(
                endlessConfig(_theme,
                    twoWay: _twoWay, seed: math.Random().nextInt(100000)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
