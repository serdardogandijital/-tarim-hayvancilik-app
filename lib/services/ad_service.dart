import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._internal();

  static final AdService instance = AdService._internal();

  RewardedInterstitialAd? _rewardedAd;
  bool _isLoadingRewarded = false;
  bool _shouldShowOnceLoaded = false;
  Timer? _startupTimer;
  Timer? _recurringTimer;

  Future<void> initialize() async {
    if (!_supportsMobileAds) return;

    await MobileAds.instance.initialize();
    await _loadRewardedInterstitial();
  }

  void startAdSchedule() {
    if (_startupTimer != null) return;
    if (!_supportsMobileAds) return;

    _startupTimer = Timer(const Duration(seconds: 15), () {
      _requestRewardedInterstitial();
      _recurringTimer?.cancel();
      _recurringTimer =
          Timer.periodic(const Duration(minutes: 5), (_) => _requestRewardedInterstitial());
    });
  }

  void _requestRewardedInterstitial() {
    if (_rewardedAd != null) {
      _showRewardedAd();
      return;
    }

    _shouldShowOnceLoaded = true;
    unawaited(_loadRewardedInterstitial());
  }

  Future<void> _loadRewardedInterstitial() async {
    if (_isLoadingRewarded) return;
    if (!_supportsMobileAds) return;

    _isLoadingRewarded = true;

    await RewardedInterstitialAd.load(
      adUnitId: _rewardedInterstitialUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoadingRewarded = false;
          _attachFullScreenCallbacks(ad);

          if (_shouldShowOnceLoaded) {
            _shouldShowOnceLoaded = false;
            _showRewardedAd();
          }
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded interstitial failed to load: $error');
          _isLoadingRewarded = false;
          _rewardedAd = null;

          // Retry with simple backoff to avoid spamming the network.
          unawaited(Future<void>.delayed(const Duration(seconds: 3), () {
            _loadRewardedInterstitial();
          }));
        },
      ),
    );
  }

  void _showRewardedAd() {
    final ad = _rewardedAd;
    if (ad == null) {
      _shouldShowOnceLoaded = true;
      unawaited(_loadRewardedInterstitial());
      return;
    }

    ad.show(onUserEarnedReward: (adWithoutView, reward) {
      debugPrint('User earned reward: ${reward.amount} ${reward.type}');
    });
    _rewardedAd = null;
  }

  void _attachFullScreenCallbacks(RewardedInterstitialAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('Rewarded interstitial showed.');
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Rewarded interstitial failed to show: $error');
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedInterstitial();
      },
    );
  }

  bool get _supportsMobileAds => Platform.isAndroid || Platform.isIOS;

  String get _rewardedInterstitialUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3063450268551990/8392704645';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3063450268551990/8392704645';
    }

    throw UnsupportedError('Unsupported platform for mobile ads.');
  }
}
