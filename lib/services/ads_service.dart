import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsService {
  static final AdsService _instance = AdsService._();
  factory AdsService() => _instance;
  AdsService._();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      // Configure test device ID provided by user
      const testDeviceIds = ['FDB6404EE2DF76ABCA39527BDAFAB242'];
      final configuration = RequestConfiguration(testDeviceIds: testDeviceIds);
      await MobileAds.instance.updateRequestConfiguration(configuration);

      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('AdsService initialized');
    } catch (e) {
      debugPrint('AdsService initialization failed: $e');
    }
  }

  // --- Ad Unit IDs (Production IDs) ---
  String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-9043208558525567/7176908432'; // Android Banner
    } else if (Platform.isIOS) {
      return 'ca-app-pub-9043208558525567/9989999959'; // iOS Banner
    }
    // Fallback to test ID for safety if platform not matched, or return empty
    return 'ca-app-pub-3940256099942544/6300978111';
  }

  String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-9043208558525567/7040837757'; // Android Interstitial
    } else if (Platform.isIOS) {
      return 'ca-app-pub-9043208558525567/8158043532'; // iOS Interstitial
    }
    // Fallback to test ID
    return 'ca-app-pub-3940256099942544/1033173712';
  }

  // --- Ad Loading Helpers ---

  // --- Additional Ad Unit IDs ---

  String get rewardedInterstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-9043208558525567/8422541493';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-9043208558525567/6534744752';
    }
    return 'ca-app-pub-3940256099942544/5354046379'; // Test ID
  }

  String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-9043208558525567/4232015044';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-9043208558525567/4834650270';
    }
    return 'ca-app-pub-3940256099942544/5224354917'; // Test ID
  }

  String get nativeAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-9043208558525567/8349615222';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-9043208558525567/9279553514';
    }
    return 'ca-app-pub-3940256099942544/2247696110'; // Test ID
  }

  String get appOpenAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-9043208558525567/5604806467';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-9043208558525567/7966471843';
    }
    return 'ca-app-pub-3940256099942544/3419835294'; // Test ID
  }

  // --- Ad Loading Helpers ---

  Future<void> showInterstitialAd() async {
    if (!_isInitialized) await initialize();
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (InterstitialAd ad) {
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent:
                (InterstitialAd ad, AdError error) {
              ad.dispose();
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  // --- Ad Pre-loading ---
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoading = false;
  DateTime? _rewardedAdLoadTime;

  bool get isRewardedAdAvailable {
    return _rewardedAd != null &&
        _rewardedAdLoadTime != null &&
        DateTime.now().difference(_rewardedAdLoadTime!) <
            const Duration(hours: 4);
  }

  Future<void> loadRewardedAd() async {
    if (_isRewardedAdLoading || isRewardedAdAvailable) return;
    if (!_isInitialized) await initialize();

    _isRewardedAdLoading = true;
    debugPrint('Loading RewardedAd...');

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _isRewardedAdLoading = false;
          _rewardedAdLoadTime = DateTime.now();
          debugPrint('RewardedAd loaded and ready.');
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isRewardedAdLoading = false;
          debugPrint('RewardedAd failed to load: $error');
        },
      ),
    );
  }

  Future<void> showRewardedAd({
    required Function(RewardItem) onUserEarnedReward,
    VoidCallback? onAdDismissed,
    Function(LoadAdError)? onAdFailedToLoad,
  }) async {
    if (!_isInitialized) await initialize();

    // If ad is available, show it
    if (isRewardedAdAvailable) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (RewardedAd ad) {
          ad.dispose();
          _rewardedAd = null;
          if (onAdDismissed != null) onAdDismissed();
          loadRewardedAd(); // Pre-load next one
        },
        onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
          ad.dispose();
          _rewardedAd = null;
          loadRewardedAd();
        },
      );

      _rewardedAd!.show(
          onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        onUserEarnedReward(reward);
      });
      return;
    }

    // If no ad pre-loaded, try loading one immediately (user might have to wait)
    _isRewardedAdLoading = true;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _isRewardedAdLoading = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (RewardedAd ad) {
              ad.dispose();
              if (onAdDismissed != null) onAdDismissed();
              loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
              ad.dispose();
              loadRewardedAd();
            },
          );
          ad.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
            onUserEarnedReward(reward);
          });
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isRewardedAdLoading = false;
          debugPrint('RewardedAd failed to load: $error');
          if (onAdFailedToLoad != null) onAdFailedToLoad(error);
          loadRewardedAd(); // Try again for background
        },
      ),
    );
  }

  Future<void> showRewardedInterstitialAd(
      {required Function(RewardItem) onUserEarnedReward}) async {
    if (!_isInitialized) await initialize();
    RewardedInterstitialAd.load(
      adUnitId: rewardedInterstitialAdUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (RewardedInterstitialAd ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (RewardedInterstitialAd ad) {
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent:
                (RewardedInterstitialAd ad, AdError error) {
              ad.dispose();
            },
          );
          ad.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
            onUserEarnedReward(reward);
          });
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('RewardedInterstitialAd failed to load: $error');
        },
      ),
    );
  }

  AppOpenAd? _appOpenAd;
  bool _isShowingAppOpenAd = false;
  DateTime? _appOpenLoadTime;

  void loadAppOpenAd() {
    AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _appOpenLoadTime = DateTime.now();
          debugPrint('AppOpenAd loaded');
        },
        onAdFailedToLoad: (error) {
          debugPrint('AppOpenAd failed to load: $error');
        },
      ),
    );
  }

  bool get _isAppOpenAdAvailable {
    return _appOpenAd != null &&
        _appOpenLoadTime != null &&
        DateTime.now().difference(_appOpenLoadTime!) < const Duration(hours: 4);
  }

  void showAppOpenAdIfAvailable() {
    if (!_isInitialized) return;
    if (!_isAppOpenAdAvailable) {
      loadAppOpenAd();
      return;
    }
    if (_isShowingAppOpenAd) return;

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAppOpenAd = true;
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAppOpenAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAppOpenAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
      },
    );
    _appOpenAd!.show();
  }
}

class BannerAdWidget extends StatefulWidget {
  final AdSize adSize;

  const BannerAdWidget({
    super.key,
    this.adSize = AdSize.banner,
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final adsService = AdsService();
    _bannerAd = BannerAd(
      adUnitId: adsService.bannerAdUnitId,
      request: const AdRequest(),
      size: widget.adSize,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('BannerAd failed to load: $error');
        },
      ),
    );
    _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoaded && _bannerAd != null) {
      return Center(
        child: SizedBox(
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({super.key});

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  BannerAd?
      _nativeAd; // Switching to BannerAd for medium rectangle to avoid factory errors
  bool _nativeAdIsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final adsService = AdsService();
    _nativeAd = BannerAd(
      adUnitId: adsService.nativeAdUnitId,
      request: const AdRequest(),
      size: AdSize.mediumRectangle,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _nativeAdIsLoaded = true;
          });
          debugPrint('Medium Rectangle Ad loaded');
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Medium Rectangle Ad failed to load: $error');
        },
      ),
    );
    _nativeAd?.load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_nativeAdIsLoaded && _nativeAd != null) {
      return Container(
        width: double.infinity,
        height: _nativeAd!.size.height.toDouble(),
        alignment: Alignment.center,
        child: AdWidget(ad: _nativeAd!),
      );
    }
    return const SizedBox.shrink();
  }
}
