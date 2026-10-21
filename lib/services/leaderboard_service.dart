import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:games_services/games_services.dart';

/// The endless-run high score board: Google Play Games on Android, Game
/// Center on iOS.
///
/// Every platform call is wrapped in a timeout as well as a try/catch: with
/// no native handler (tests, or a device without Play Services) the plugin's
/// method-channel future can simply never complete, and the game must never
/// wait on it. The timeout is long enough for a first-time sign-in consent
/// sheet that the player has to tap.
class LeaderboardService {
  /// From Play Console. The Play Games project id it belongs to is in
  /// android/app/src/main/res/values/games_ids.xml.
  static const _androidId = 'CgkIgb-PsbgbEAIQAg';

  /// iOS ids are chosen by us when the board is created in App Store
  /// Connect; it must be created with exactly this id.
  static const _iosId = 'xexua_endless';

  static const _timeout = Duration(seconds: 12);

  /// Widget tests run as "Android" with no plugin behind the channel; this
  /// keeps them from leaving a 12-second timeout pending.
  @visibleForTesting
  static bool disabled = false;

  static bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android || _isIOS);

  static bool get _configured =>
      !disabled &&
      _supported && !(_isIOS ? _iosId : _androidId).startsWith('REPLACE');

  static Future<void> signIn() async {
    if (!_configured) return;
    try {
      await GameAuth.signIn().timeout(_timeout);
    } catch (_) {
      // No account, no network, not set up yet: play on without a board.
    }
  }

  /// Fire-and-forget after an endless run.
  static void submitEndless(int score) {
    if (!_configured || score <= 0) return;
    unawaited(() async {
      try {
        await Leaderboards.submitScore(
          score: Score(
            androidLeaderboardID: _androidId,
            iOSLeaderboardID: _iosId,
            value: score,
          ),
        ).timeout(_timeout);
      } catch (_) {}
    }());
  }

  /// Opens the platform's own board. False if it could not, so the caller
  /// can say so instead of doing nothing.
  static Future<bool> show() async {
    if (!_configured) return false;
    try {
      await GameAuth.signIn().timeout(_timeout);
      await Leaderboards.showLeaderboards(
        androidLeaderboardID: _androidId,
        iOSLeaderboardID: _iosId,
      ).timeout(_timeout);
      return true;
    } catch (_) {
      return false;
    }
  }
}
