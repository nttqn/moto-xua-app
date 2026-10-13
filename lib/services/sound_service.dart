import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Sfx { crash, whoosh, bump, scrape, boost, beep, go, win, fail, click, coin }

/// One-shot effects, a looping engine note whose pitch follows the speedo,
/// and the menu theme. Effects and engine are synthesised by
/// `tool/gen_audio.js`, the theme by `tool/gen_music.js`.
///
/// `init()` is fired unawaited from `main()`: a broken asset can leave pool
/// creation hanging on web, and that must never hold up the first frame.
/// Every call here is a safe no-op until loading is done or when muted.
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  static const _key = 'sound_enabled';

  final ValueNotifier<bool> enabled = ValueNotifier<bool>(true);
  final Map<Sfx, AudioPool> _pools = {};
  AudioPlayer? _engine;
  bool _engineWanted = false;
  bool _engineRunning = false;
  double _lastRate = 0;

  AudioPlayer? _music;
  bool _menuMusic = false;
  int _rides = 0;
  bool _foreground = true;
  AppLifecycleListener? _lifecycle;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      enabled.value = prefs.getBool(_key) ?? true;
    } catch (_) {}
    try {
      // By default every player asks Android for audio focus when it
      // starts, which pauses whichever player had it: each effect would cut
      // the engine note. Nothing here needs focus, so nobody takes it.
      await AudioPlayer.global.setAudioContext(AudioContext(
        android: const AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
        iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
      ));
    } catch (_) {}
    for (final s in Sfx.values) {
      try {
        _pools[s] = await FlameAudio.createPool(
          '${s.name}.wav',
          minPlayers: 1,
          maxPlayers: s == Sfx.whoosh ? 3 : 2,
        ).timeout(const Duration(seconds: 5));
      } catch (_) {
        // That one effect just stays silent.
      }
    }
    try {
      final player = AudioPlayer();
      // Low-latency mode is SoundPool on Android: it loops a short sample
      // with no gap and changes pitch without a hiccup, which the default
      // MediaPlayer does not.
      await player.setPlayerMode(PlayerMode.lowLatency);
      await player.setReleaseMode(ReleaseMode.loop);
      try {
        await player
            .setSource(AssetSource('audio/engine.wav'))
            .timeout(const Duration(seconds: 5));
      } on TimeoutException {
        // Keep the player: the sample may simply finish loading late.
      }
      _engine = player;
      if (_engineWanted) startEngine();
    } catch (_) {}
    try {
      final player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(0.55);
      await player
          .setSource(AssetSource('audio/menu.wav'))
          .timeout(const Duration(seconds: 10));
      _music = player;
    } catch (_) {}
    // Nothing holds audio focus, so nothing stops the music when the app
    // goes to the background unless it is done here.
    _lifecycle ??= AppLifecycleListener(
      onStateChange: (state) {
        _foreground = state == AppLifecycleState.resumed;
        _applyMusic();
      },
    );
    _applyMusic();
  }

  /// Menus call this; the theme then plays whenever no ride is on screen.
  void playMenuMusic() {
    _menuMusic = true;
    _applyMusic();
  }

  /// Rides count themselves in and out rather than stopping and starting
  /// the theme, because going straight to the next stage builds the new
  /// ride screen before the old one is disposed.
  void rideStarted() {
    _rides++;
    _applyMusic();
  }

  void rideEnded() {
    if (_rides > 0) _rides--;
    _applyMusic();
  }

  void _applyMusic() {
    final music = _music;
    if (music == null) return;
    final should =
        _menuMusic && _rides == 0 && enabled.value && _foreground;
    final playing = music.state == PlayerState.playing;
    if (should && !playing) {
      _guard(music.resume());
    } else if (!should && playing) {
      _guard(music.pause());
    }
  }

  void play(Sfx s, {double volume = 1}) {
    // A browser refuses to start audio before the first tap; effects only
    // ever follow one, so this is where a blocked theme gets going.
    _applyMusic();
    if (!enabled.value) return;
    try {
      _pools[s]?.start(volume: volume);
    } catch (_) {}
  }

  void startEngine() {
    _engineWanted = true;
    if (!enabled.value || _engine == null || _engineRunning) return;
    _engineRunning = true;
    _lastRate = 0;
    _guard(_engine!.resume());
  }

  /// [rev] 0..1 of the bike's range; [voice] shifts the whole note so a
  /// big single sounds lower than a Cub.
  void revEngine(double rev, {double voice = 1}) {
    if (!_engineRunning) return;
    // 0.5..2.0 is all SoundPool allows.
    final rate =
        ((0.6 + 1.15 * rev.clamp(0, 1)) * voice).clamp(0.5, 2.0).toDouble();
    if ((rate - _lastRate).abs() < 0.03) return;
    _lastRate = rate;
    _guard(_engine!.setPlaybackRate(rate));
    _guard(_engine!.setVolume(0.3 + 0.35 * rev.clamp(0, 1)));
  }

  void stopEngine() {
    _engineWanted = false;
    if (!_engineRunning) return;
    _engineRunning = false;
    _guard(_engine!.pause());
  }

  Future<void> toggle() async {
    enabled.value = !enabled.value;
    if (!enabled.value && _engineRunning) {
      _engineRunning = false;
      _guard(_engine!.pause());
    } else if (enabled.value && _engineWanted) {
      startEngine();
    }
    _applyMusic();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, enabled.value);
    } catch (_) {}
  }

  static void _guard(Future<void> f) {
    f.catchError((Object _) {});
  }
}
