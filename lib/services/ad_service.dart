import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdService {
  AdService._internal();

  static final AdService instance = AdService._internal();

  RewardedInterstitialAd? _rewardedAd;
  bool _isLoadingRewarded = false;
  bool _hasShownStartupAd = false;
  bool _shouldShowOnceLoaded = false;

  Future<void> initialize() async {
    if (!_supportsMobileAds) return;

    await MobileAds.instance.initialize();
    await _loadRewardedInterstitial();
  }

  Future<void> showStartupRewardedAd() async {
    if (_hasShownStartupAd) return;
    _hasShownStartupAd = true;

    if (_rewardedAd != null) {
      _showRewardedAd();
    } else {
      _shouldShowOnceLoaded = true;
      await _loadRewardedInterstitial();
    }
  }

  Future<void> maybeShowStartupRewardedAd() async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'startup_rewarded_ad_shown';
    final alreadyShown = prefs.getBool(key) ?? false;

    if (alreadyShown) return;

    await showStartupRewardedAd();
    await prefs.setBool(key, true);
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
      return 'ca-app-pub-3940256099942544/5354046379';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/6978759866';
    }

    throw UnsupportedError('Unsupported platform for mobile ads.');
  }
}
