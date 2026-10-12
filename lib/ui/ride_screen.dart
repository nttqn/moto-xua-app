import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/bikes.dart';
import '../core/content.dart';
import '../core/world.dart';
import '../game/ride_game.dart';
import '../services/progress.dart';
import '../services/sound_service.dart';
import 'theme.dart';

/// One ride of any mode, with its HUD, touch controls, pause and result.
class RideScreen extends StatefulWidget {
  const RideScreen({
    super.key,
    required this.config,
    required this.title,
    this.stageIndex,
    this.missionIndex,
  });

  final RunConfig config;
  final String title;
  final int? stageIndex;
  final int? missionIndex;

  @override
  State<RideScreen> createState() => _RideScreenState();
}

class _Outcome {
  _Outcome(this.headline, this.lines, this.stars, this.pay, this.good);
  final String headline;
  final List<String> lines;
  final int stars;
  final int pay;
  final bool good;
}

class _RideScreenState extends State<RideScreen> {
  late RideGame _game;
  late World _world;
  bool _paused = false;
  _Outcome? _outcome;
  String _popup = '';
  int _popupId = 0;
  Timer? _popupTimer;
  Timer? _resultTimer;

  final Map<int, int> _pointers = {};
  final Set<LogicalKeyboardKey> _keys = {};
  bool _brakeTouch = false;
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    final progress = Progress.instance;
    _world = World(widget.config, progress.stats);
    _game = RideGame(
      world: _world,
      bike: progress.selected,
      onEvent: _onEvent,
    );
    _game.hudTick.addListener(_onTick);
    _paused = false;
    _outcome = null;
    _popup = '';
    _pointers.clear();
    _keys.clear();
    _brakeTouch = false;
    _lastCount = 4;
    SoundService.instance.startEngine();
  }

  int _lastCount = 4;

  /// A big single thumps lower than a Cub.
  static const _voices = {
    BikeId.cub: 1.0,
    BikeId.wave: 1.12,
    BikeId.dream: 0.94,
    BikeId.x67: 0.82,
  };

  void _onTick() {
    final w = _world;
    if (w.phase == Phase.countdown) {
      final count = w.countdown.ceil();
      if (count != _lastCount && count <= 3) {
        _lastCount = count;
        SoundService.instance.play(Sfx.beep);
      }
    }
    SoundService.instance.revEngine(
      w.fallen ? 0 : w.speed / w.stats.topSpeed,
      voice: _voices[Progress.instance.selected]!,
    );
  }

  @override
  void dispose() {
    _game.hudTick.removeListener(_onTick);
    SoundService.instance.stopEngine();
    _popupTimer?.cancel();
    _resultTimer?.cancel();
    _focus.dispose();
    super.dispose();
  }

  void _onEvent(WorldEvent e) {
    final sound = SoundService.instance;
    switch (e) {
      case WorldEvent.go:
        sound.play(Sfx.go);
      case WorldEvent.crash:
        sound.play(Sfx.crash);
      case WorldEvent.nearMiss:
        sound.play(Sfx.whoosh);
      case WorldEvent.bump:
        sound.play(Sfx.bump);
      case WorldEvent.finish:
        // A race finished outside the top three is no fanfare.
        sound.play(_world.success ? Sfx.win : Sfx.fail);
        sound.stopEngine();
      case WorldEvent.fail:
        sound.play(Sfx.fail);
        sound.stopEngine();
      case WorldEvent.overtake:
        break;
    }
    switch (e) {
      case WorldEvent.go:
        _say('XUẤT PHÁT!');
      case WorldEvent.crash:
        HapticFeedback.heavyImpact();
        _say(_world.config.mode == RunMode.endless && _world.lives > 0
            ? 'NGÃ XE!  còn ${_world.lives} mạng'
            : 'NGÃ XE!');
      case WorldEvent.nearMiss:
        HapticFeedback.selectionClick();
        _say(_world.combo > 1 ? 'LÁCH SÁT  x${_world.combo}' : 'LÁCH SÁT!');
      case WorldEvent.finish:
      case WorldEvent.fail:
        // Let the bike roll on for a beat before the board comes up.
        _resultTimer = Timer(const Duration(milliseconds: 1400), _showResult);
      case WorldEvent.bump:
      case WorldEvent.overtake:
        break;
    }
  }

  void _say(String text) {
    _popupTimer?.cancel();
    setState(() {
      _popup = text;
      _popupId++;
    });
    _popupTimer = Timer(const Duration(milliseconds: 1300), () {
      if (mounted) setState(() => _popup = '');
    });
  }

  void _showResult() {
    if (!mounted) return;
    final w = _world;
    final progress = Progress.instance;
    final _Outcome outcome;
    switch (w.config.mode) {
      case RunMode.endless:
        final record = w.score > progress.bestScore;
        final pay = progress.recordEndless(w.score);
        outcome = _Outcome(record ? 'KỶ LỤC MỚI!' : 'HẾT MẠNG', [
          'Điểm: ${w.score}',
          'Quãng đường: ${(w.distanceMeters / 1000).toStringAsFixed(2)} km',
          'Lách sát: ${w.nearMisses}   Chuỗi dài nhất: x${w.bestCombo}',
          'Kỷ lục: ${progress.bestScore}',
        ], 0, pay, record);
      case RunMode.race:
        final pay = progress.recordStage(widget.stageIndex!, w.position);
        outcome = _Outcome(
          w.position == 1 ? 'VỀ NHẤT!' : 'VỀ THỨ ${w.position}',
          [
            'Thời gian: ${_clock(w.time)}',
            if (w.position > 3) 'Vào tốp 3 mới mở được chặng sau.',
          ],
          raceStars(w.position),
          pay,
          w.position <= 3,
        );
      case RunMode.mission:
        if (w.success) {
          final stars = missionStars(w.timeLeft, w.config.timeLimit);
          final pay = progress.recordMission(widget.missionIndex!, stars);
          outcome = _Outcome('XONG VIỆC!', [
            'Thời gian: ${_clock(w.time)} / ${_clock(w.config.timeLimit)}',
            if (w.crashes > 0) 'Ngã ${w.crashes} lần',
          ], stars, pay, true);
        } else {
          outcome = _Outcome('HỎNG VIỆC', [w.failReason], 0, 0, false);
        }
    }
    setState(() => _outcome = outcome);
  }

  static String _clock(double seconds) {
    final s = seconds.floor();
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  void _togglePause() {
    if (_outcome != null || _world.phase == Phase.finished) return;
    setState(() {
      _paused = !_paused;
      if (_paused) {
        _game.pauseEngine();
        SoundService.instance.stopEngine();
      } else {
        _game.resumeEngine();
        SoundService.instance.startEngine();
      }
      _pointers.clear();
      _syncInput();
    });
  }

  void _restart() {
    _resultTimer?.cancel();
    _game.hudTick.removeListener(_onTick);
    setState(_start);
  }

  void _syncInput() {
    var steer = 0.0;
    if (_pointers.containsValue(-1)) steer -= 1;
    if (_pointers.containsValue(1)) steer += 1;
    if (_keys.contains(LogicalKeyboardKey.arrowLeft) ||
        _keys.contains(LogicalKeyboardKey.keyA)) {
      steer -= 1;
    }
    if (_keys.contains(LogicalKeyboardKey.arrowRight) ||
        _keys.contains(LogicalKeyboardKey.keyD)) {
      steer += 1;
    }
    _game.steerInput = steer.clamp(-1, 1).toDouble();
    _game.brakeInput = _brakeTouch ||
        _keys.contains(LogicalKeyboardKey.arrowDown) ||
        _keys.contains(LogicalKeyboardKey.space) ||
        _keys.contains(LogicalKeyboardKey.keyS);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape ||
          event.logicalKey == LogicalKeyboardKey.keyP) {
        _togglePause();
        return KeyEventResult.handled;
      }
      _keys.add(event.logicalKey);
    } else if (event is KeyUpEvent) {
      _keys.remove(event.logicalKey);
    }
    _syncInput();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return PopScope(
      // Back pauses mid-ride; it only leaves once the ride is over.
      canPop: _outcome != null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _togglePause();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Focus(
          focusNode: _focus,
          autofocus: true,
          onKeyEvent: _onKey,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (e) {
                  _pointers[e.pointer] = e.position.dx < width / 2 ? -1 : 1;
                  _syncInput();
                },
                onPointerMove: (e) {
                  if (!_pointers.containsKey(e.pointer)) return;
                  _pointers[e.pointer] = e.position.dx < width / 2 ? -1 : 1;
                  _syncInput();
                },
                onPointerUp: (e) {
                  _pointers.remove(e.pointer);
                  _syncInput();
                },
                onPointerCancel: (e) {
                  _pointers.remove(e.pointer);
                  _syncInput();
                },
                child: GameWidget(key: ValueKey(_game), game: _game),
              ),
              ValueListenableBuilder<int>(
                valueListenable: _game.hudTick,
                builder: (context, _, _) => _Hud(
                  world: _world,
                  title: widget.title,
                  onPause: _togglePause,
                ),
              ),
              _controls(),
              if (_popup.isNotEmpty)
                Align(
                  alignment: const Alignment(0, -0.42),
                  child: IgnorePointer(
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey(_popupId),
                      tween: Tween(begin: 0.6, end: 1),
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutBack,
                      builder: (context, t, child) =>
                          Transform.scale(scale: t, child: child),
                      child: _outlined(_popup, 26, signYellow),
                    ),
                  ),
                ),
              if (_paused) _pauseOverlay(),
              if (_outcome != null) _resultOverlay(_outcome!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _outlined(String text, double size, Color color) {
    return Stack(
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: signText.copyWith(
            fontSize: size,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 5
              ..color = const Color(0xFF2A1A12),
          ),
        ),
        Text(
          text,
          textAlign: TextAlign.center,
          style: signText.copyWith(fontSize: size, color: color),
        ),
      ],
    );
  }

  Widget _controls() {
    Widget hint(IconData icon) => IgnorePointer(
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 2),
        ),
        child: Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 40),
      ),
    );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              hint(Icons.arrow_left_rounded),
              Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (_) {
                  _brakeTouch = true;
                  _syncInput();
                },
                onPointerUp: (_) {
                  _brakeTouch = false;
                  _syncInput();
                },
                onPointerCancel: (_) {
                  _brakeTouch = false;
                  _syncInput();
                },
                child: Container(
                  width: 112,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: signRed.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFF3C4), width: 2),
                  ),
                  child: Text(
                    'PHANH',
                    style: signText.copyWith(
                      color: const Color(0xFFFFF3C4),
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              hint(Icons.arrow_right_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _board({required List<Widget> children}) {
    return Container(
      color: Colors.black.withValues(alpha: 0.62),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(28),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        decoration: BoxDecoration(
          color: paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ink, width: 3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }

  Widget _pauseOverlay() {
    return _board(children: [
      Text('TẠM DỪNG',
          textAlign: TextAlign.center,
          style: signText.copyWith(fontSize: 28, color: signRed)),
      const SizedBox(height: 6),
      Text(widget.title, textAlign: TextAlign.center),
      const SizedBox(height: 18),
      SignButton(label: 'CHẠY TIẾP', onTap: _togglePause, color: signTeal),
      const SizedBox(height: 10),
      SignButton(label: 'CHẠY LẠI', onTap: _restart, color: signBlue),
      const SizedBox(height: 10),
      SignButton(
        label: 'THOÁT',
        onTap: () => Navigator.of(context).pop(),
        color: ink,
      ),
    ]);
  }

  Widget _resultOverlay(_Outcome o) {
    final next = widget.stageIndex != null &&
        widget.stageIndex! + 1 < stages.length &&
        Progress.instance.stageUnlocked(widget.stageIndex! + 1);
    final nextMission = widget.missionIndex != null &&
        widget.missionIndex! + 1 < missions.length &&
        Progress.instance.missionUnlocked(widget.missionIndex! + 1);
    return _board(children: [
      Text(o.headline,
          textAlign: TextAlign.center,
          style: signText.copyWith(
              fontSize: 28, color: o.good ? signTeal : signRed)),
      const SizedBox(height: 4),
      Text(widget.title, textAlign: TextAlign.center),
      if (_world.config.mode != RunMode.endless && o.good) ...[
        const SizedBox(height: 8),
        Center(child: Stars(o.stars, size: 40)),
      ],
      const SizedBox(height: 10),
      for (final line in o.lines)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(line,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15)),
        ),
      if (o.pay > 0) ...[
        const SizedBox(height: 10),
        Text('+ ${money(o.pay)}',
            textAlign: TextAlign.center,
            style: signText.copyWith(
                fontSize: 24, color: const Color(0xFFB07A08))),
      ],
      const SizedBox(height: 16),
      if (next && o.good)
        SignButton(
          label: 'CHẶNG TIẾP',
          color: signTeal,
          onTap: () => _goTo(RideScreen(
            config: stageConfig(widget.stageIndex! + 1),
            title: stages[widget.stageIndex! + 1].title,
            stageIndex: widget.stageIndex! + 1,
          )),
        ),
      if (nextMission && o.good)
        SignButton(
          label: 'VIỆC TIẾP THEO',
          color: signTeal,
          onTap: () => _goTo(RideScreen(
            config: missionConfig(widget.missionIndex! + 1),
            title: missions[widget.missionIndex! + 1].title,
            missionIndex: widget.missionIndex! + 1,
          )),
        ),
      if ((next || nextMission) && o.good) const SizedBox(height: 10),
      SignButton(label: 'CHẠY LẠI', onTap: _restart, color: signBlue),
      const SizedBox(height: 10),
      SignButton(
        label: 'VỀ',
        onTap: () => Navigator.of(context).pop(),
        color: ink,
      ),
    ]);
  }

  void _goTo(Widget screen) {
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute<void>(builder: (_) => screen));
  }
}

class _Hud extends StatelessWidget {
  const _Hud({required this.world, required this.title, required this.onPause});

  final World world;
  final String title;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final w = world;
    final cfg = w.config;
    final chips = <Widget>[];
    switch (cfg.mode) {
      case RunMode.endless:
        chips.add(_chip('ĐIỂM', '${w.score}'));
        chips.add(_chip('MẠNG', '♥' * w.lives.clamp(0, 9), color: signRed));
        if (w.combo > 1) chips.add(_chip('CHUỖI', 'x${w.combo}'));
      case RunMode.race:
        chips.add(_chip('HẠNG', '${w.position}/${w.racers.length + 1}'));
        chips.add(_chip('CÒN', '${w.remainingMeters.round()} m'));
      case RunMode.mission:
        final urgent = w.timeLeft < 10;
        chips.add(_chip('GIỜ', _RideScreenState._clock(w.timeLeft),
            color: urgent ? signRed : null));
        switch (cfg.goal) {
          case GoalType.deliver:
            chips.add(_chip('CÒN', '${w.remainingMeters.round()} m'));
          case GoalType.overtake:
            chips.add(_chip('VƯỢT', '${w.overtakes}/${cfg.goalCount}'));
          case GoalType.nearMiss:
            chips.add(_chip('LÁCH', '${w.nearMisses}/${cfg.goalCount}'));
        }
        if (cfg.maxCrashes >= 0) {
          final left = (cfg.maxCrashes - w.crashes + 1).clamp(0, 9);
          chips.add(_chip('HÀNG', left > 0 ? '♥' * left : 'VỠ', color: signRed));
        }
    }
    final showBar = cfg.mode != RunMode.endless;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _round(Icons.pause_rounded, onPause),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(spacing: 6, runSpacing: 6, children: chips),
                ),
                const SizedBox(width: 8),
                _speedo(w),
              ],
            ),
            if (showBar) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: w.progress,
                  minHeight: 8,
                  backgroundColor: Colors.black.withValues(alpha: 0.35),
                  color: signYellow,
                ),
              ),
            ],
            if (w.phase == Phase.countdown)
              Expanded(
                child: Align(
                  alignment: const Alignment(0, -0.3),
                  child: Text(
                    '${w.countdown.ceil().clamp(1, 3)}',
                    style: signText.copyWith(
                      fontSize: 110,
                      color: signYellow,
                      shadows: const [
                        Shadow(color: Color(0xFF2A1A12), blurRadius: 0, offset: Offset(4, 4)),
                      ],
                    ),
                  ),
                ),
              ),
            if (w.inOncomingLane && w.phase == Phase.running)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'NGƯỢC CHIỀU  +ĐIỂM',
                  style: signText.copyWith(
                    fontSize: 13,
                    color: const Color(0xFFFFF3C4),
                    shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _round(IconData icon, VoidCallback onTap) => Material(
    color: Colors.black.withValues(alpha: 0.55),
    shape: const CircleBorder(),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    ),
  );

  Widget _chip(String label, String value, {Color? color}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: (color ?? Colors.black).withValues(alpha: color == null ? 0.55 : 0.85),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: const TextStyle(
                color: Color(0xCCFFFFFF), fontSize: 10, fontWeight: FontWeight.w700)),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
      ],
    ),
  );

  Widget _speedo(World w) => Container(
    width: 76,
    padding: const EdgeInsets.symmetric(vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xE62A1A12),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: signYellow, width: 2),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${w.speedKmh.round()}',
          style: signText.copyWith(fontSize: 26, color: signYellow),
        ),
        const Text('km/h',
            style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 11)),
      ],
    ),
  );
}

/// Shown before a ride so the selected bike is never a surprise.
String bikeLine() {
  final spec = bikeSpec(Progress.instance.selected);
  return '${spec.name} · ${Progress.instance.stats.topKmh.round()} km/h';
}
