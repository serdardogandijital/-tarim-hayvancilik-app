import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

/// Space is reserved in the Scaffold, never laid over fields or buttons.
class BottomBanner extends StatefulWidget {
  const BottomBanner({super.key});
  @override
  State<BottomBanner> createState() => _BottomBannerState();
}

class _BottomBannerState extends State<BottomBanner> {
  BannerAd? _ad;
  bool _loaded = false;
  int? _requestedWidth;
  @override
  void initState() {
    super.initState();
    AdsConsent.instance.addListener(_consentChanged);
  }

  void _consentChanged() {
    if (!mounted) return;
    if (!AdsConsent.instance.allowed) {
      _ad?.dispose();
      _ad = null;
      _loaded = false;
      _requestedWidth = null;
    }
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final width = MediaQuery.sizeOf(context).width.floor() - 32;
    if (AdUnits.banner.isEmpty || width <= 0 || _requestedWidth == width) {
      return;
    }
    _requestedWidth = width;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(width));
  }

  Future<void> _load(int width) async {
    try {
      if (!mounted || !await AdsConsent.instance.initialize() || !mounted) {
        return;
      }
      final size =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
      if (!mounted ||
          size == null ||
          _requestedWidth != width ||
          !AdsConsent.instance.allowed) {
        return;
      }
      _ad?.dispose();
      _ad = null;
      setState(() => _loaded = false);
      final banner = BannerAd(
        size: size,
        adUnitId: AdUnits.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (!mounted || ad != _ad || !AdsConsent.instance.allowed) {
              ad.dispose();
              return;
            }
            setState(() => _loaded = true);
          },
          onAdFailedToLoad: (ad, _) {
            ad.dispose();
            if (mounted && ad == _ad) {
              setState(() {
                _ad = null;
                _loaded = false;
              });
            }
          },
        ),
      );
      _ad = banner;
      await banner.load();
    } catch (_) {
      // No rapid retry loop and no empty ad placeholder on load failure.
      if (mounted) setState(() => _loaded = false);
    }
  }

  @override
  void dispose() {
    AdsConsent.instance.removeListener(_consentChanged);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.viewInsetsOf(context).bottom > 0) {
      return const SizedBox.shrink();
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_loaded && _ad != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Reklam',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: _ad!.size.width.toDouble(),
                  height: _ad!.size.height.toDouble(),
                  child: AdWidget(ad: _ad!),
                ),
              ],
            ),
          ),
        if (AdsConsent.instance.privacyOptionsRequired)
          TextButton(
            onPressed: () async {
              try {
                await AdsConsent.instance.showPrivacyOptions();
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Reklam gizlilik seçenekleri açılamadı. Tekrar deneyin.',
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Reklam gizlilik seçenekleri'),
          ),
      ],
    );
  }
}
