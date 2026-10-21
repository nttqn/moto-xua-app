import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob banner + interstitial.
///
/// Each platform has the game's own ad units, since AdMob units are
/// platform-specific. The App IDs live outside this file: Android's in
/// android/app/build.gradle.kts, iOS's in ios/Runner/Info.plist.
///
/// `google_mobile_ads` only supports Android/iOS, so everything here is a
/// no-op elsewhere, which keeps `flutter run -d chrome` and tests working.
class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static String get bannerAdUnitId =>
      defaultTargetPlatform == TargetPlatform.iOS
      ? 'ca-app-pub-9078637596840810/1235629342'
      : 'ca-app-pub-9078637596840810/4087269378';

  static String get interstitialAdUnitId =>
      defaultTargetPlatform == TargetPlatform.iOS
      ? 'ca-app-pub-9078637596840810/7505524220'
      : 'ca-app-pub-9078637596840810/4411622879';

  /// Rewarded units: revive an endless run, double a ride's payout.
  static String get rewardedAdUnitId =>
      defaultTargetPlatform == TargetPlatform.iOS
      ? 'ca-app-pub-9078637596840810/9440937328'
      : 'ca-app-pub-9078637596840810/8975489739';

  /// Becomes true once the SDK has started; nothing loads before that.
  final ValueNotifier<bool> ready = ValueNotifier(false);
  bool get _ready => ready.value;
  InterstitialAd? _interstitialAd;
  int _breaksSinceInterstitial = 0;
  RewardedAd? _rewarded;
  bool _rewardedLoading = false;

  /// Whether a rewarded ad is loaded and can be offered right now.
  final ValueNotifier<bool> rewardedReady = ValueNotifier(false);

  /// Screenshots and tests: behave as if a rewarded ad is always there and
  /// grant the reward at once.
  @visibleForTesting
  bool simulateRewarded = false;

  bool get canShowRewarded => simulateRewarded || rewardedReady.value;

  Future<void> initialize() async {
    if (!_supported) return;
    try {
      await MobileAds.instance.initialize();
      ready.value = true;
      _loadInterstitial();
      _loadRewarded();
    } catch (_) {
      // Ads failing must never block the game.
    }
  }

  BannerAd? createBannerAd({required void Function() onLoaded}) {
    if (!_ready) return null;
    final banner = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded(),
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    );
    banner.load();
    return banner;
  }

  void _loadInterstitial() {
    if (!_ready) return;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (_) => _interstitialAd = null,
      ),
    );
  }

  /// Call only when a ride is over and being left, never during play.
  /// Shows at most every other break.
  void maybeShowInterstitial() {
    if (!_ready) return;
    _breaksSinceInterstitial++;
    if (_breaksSinceInterstitial < 2 || _interstitialAd == null) {
      if (_interstitialAd == null) _loadInterstitial();
      return;
    }
    _breaksSinceInterstitial = 0;
    final ad = _interstitialAd!;
    _interstitialAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadInterstitial();
      },
    );
    ad.show();
  }

  void _loadRewarded() {
    if (!_ready || _rewarded != null || _rewardedLoading) return;
    _rewardedLoading = true;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedLoading = false;
          _rewarded = ad;
          rewardedReady.value = true;
        },
        onAdFailedToLoad: (_) {
          _rewardedLoading = false;
          rewardedReady.value = false;
          // No fill is common; try again a little later.
          Timer(const Duration(seconds: 45), _loadRewarded);
        },
      ),
    );
  }

  /// Plays a rewarded ad. [onReward] runs only if the player watched it
  /// through; [onDone] always runs once the ad is gone (or could not show).
  void showRewarded({
    required VoidCallback onReward,
    required VoidCallback onDone,
  }) {
    if (simulateRewarded) {
      onReward();
      onDone();
      return;
    }
    final ad = _rewarded;
    if (ad == null) {
      onDone();
      return;
    }
    _rewarded = null;
    rewardedReady.value = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewarded();
        onDone();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadRewarded();
        onDone();
      },
    );
    ad.show(onUserEarnedReward: (_, _) => onReward());
  }
}
