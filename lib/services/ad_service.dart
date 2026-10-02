import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'analysis_credits.dart';

class AdUnits {
  static bool get mobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  // Never reuse the previous rewarded-interstitial ID for these formats.
  static String get banner => !mobile
      ? ''
      : !kReleaseMode
      ? (Platform.isAndroid
            ? 'ca-app-pub-3940256099942544/9214589741'
            : 'ca-app-pub-3940256099942544/2435281174')
      : (Platform.isAndroid
            ? const String.fromEnvironment('ADMOB_ANDROID_BANNER')
            : const String.fromEnvironment('ADMOB_IOS_BANNER'));
  static String get rewarded => !mobile
      ? ''
      : !kReleaseMode
      ? (Platform.isAndroid
            ? 'ca-app-pub-3940256099942544/5224354917'
            : 'ca-app-pub-3940256099942544/1712485313')
      : (Platform.isAndroid
            ? const String.fromEnvironment('ADMOB_ANDROID_REWARDED')
            : const String.fromEnvironment('ADMOB_IOS_REWARDED'));
}

class AdsConsent extends ChangeNotifier {
  static final instance = AdsConsent();
  Future<bool>? _initializing;
  bool allowed = false;
  bool privacyOptionsRequired = false;

  Future<bool> initialize() async {
    final attempt = _initializing ??= _initialize();
    final result = await attempt;
    if (!result && identical(attempt, _initializing)) _initializing = null;
    return result;
  }

  Future<bool> _initialize() async {
    if (!AdUnits.mobile || (AdUnits.banner.isEmpty && AdUnits.rewarded.isEmpty)) {
      return false;
    }
    try {
      final updated = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () {
          if (!updated.isCompleted) updated.complete();
        },
        (_) {
          if (!updated.isCompleted) updated.complete();
        },
      );
      await updated.future.timeout(const Duration(seconds: 20));
      await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
      allowed = await ConsentInformation.instance.canRequestAds();
      privacyOptionsRequired =
          await ConsentInformation.instance
              .getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
      if (allowed) await MobileAds.instance.initialize();
    } catch (_) {
      allowed = false;
    }
    notifyListeners();
    return allowed;
  }

  Future<void> showPrivacyOptions() async {
    await ConsentForm.showPrivacyOptionsForm((_) {});
    allowed = await ConsentInformation.instance.canRequestAds();
    notifyListeners();
  }
}

abstract class RewardedGateway {
  Future<void> show(Future<void> Function() earned);
}

class GoogleRewardedGateway implements RewardedGateway {
  @override
  Future<void> show(Future<void> Function() earned) async {
    if (AdUnits.rewarded.isEmpty ||
        !await AdsConsent.instance.initialize() ||
        !AdsConsent.instance.allowed) {
      throw StateError(
        'Reklam şu anda kullanılamıyor. Günlük bonus hakkınız devam eder.',
      );
    }
    final loaded = Completer<RewardedAd>();
    var abandoned = false;
    await RewardedAd.load(
      adUnitId: AdUnits.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (abandoned) {
            ad.dispose();
          } else {
            loaded.complete(ad);
          }
        },
        onAdFailedToLoad: (_) {
          if (!abandoned) {
            loaded.completeError(
              StateError('Reklam bulunamadı. Daha sonra tekrar deneyin.'),
            );
          }
        },
      ),
    );
    late RewardedAd ad;
    try {
      ad = await loaded.future.timeout(const Duration(seconds: 30));
    } catch (_) {
      abandoned = true;
      rethrow;
    }
    final closed = Completer<void>();
    Future<void>? rewardWrite;
    Object? rewardError;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!closed.isCompleted) closed.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        if (!closed.isCompleted) {
          closed.completeError(StateError('Reklam açılamadı.'));
        }
      },
    );
    try {
      await ad.show(
        onUserEarnedReward: (_, _) {
          // Start saving immediately, not when the ad is closed.
          rewardWrite ??= earned().catchError((Object error) {
            rewardError = error;
          });
        },
      );
      await closed.future;
      await rewardWrite;
      if (rewardError != null) throw rewardError!;
    } catch (_) {
      await ad.dispose();
      rethrow;
    }
  }
}

class RewardCredits extends ChangeNotifier {
  static final instance = RewardCredits(
    AnalysisCredits.instance,
    GoogleRewardedGateway(),
  );
  RewardCredits(this.credits, this.gateway);
  final AnalysisCredits credits;
  final RewardedGateway gateway;
  bool busy = false;
  String? _pendingReceipt;
  bool get hasPendingReward => _pendingReceipt != null;

  Future<String> earn() async {
    if (busy) return 'Reklam işlemi sürüyor.';
    busy = true;
    notifyListeners();
    try {
      if (_pendingReceipt != null) {
        await credits.grantReward(_pendingReceipt!);
        _pendingReceipt = null;
        return '1 analiz hakkı eklendi.';
      }
      await credits.refresh();
      if (!credits.ready) {
        return 'Hak kaydı okunamadı. Reklam başlatılmadı; lütfen tekrar deneyin.';
      }
      final receipt =
          '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';
      var rewarded = false;
      await gateway.show(() async {
        _pendingReceipt = receipt;
        await credits.grantReward(receipt);
        _pendingReceipt = null;
        rewarded = true;
      });
      return rewarded
          ? '1 analiz hakkı eklendi.'
          : 'Reklam tamamlanmadı. Mevcut haklarınız değişmedi.';
    } catch (_) {
      return hasPendingReward
          ? 'Ödül kaydedilemedi. Tekrar reklam izlemeden “Ödülü kaydet”e dokunun.'
          : 'Reklam şu anda açılamıyor. Daha sonra tekrar deneyebilirsiniz.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
