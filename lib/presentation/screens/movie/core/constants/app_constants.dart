/// Global application constants
class AppConstants {
  // App Info
  static const String appName = 'Movie Posters Pro';
  static const String appVersion = '10.2.25';
  static const String appVersionCode = '2';
  
  // API/Scraping Constants
  static const String tmdbBaseUrl = 'https://www.themoviedb.org';
  static const String tmdbApiBase = 'https://api.themoviedb.org/3';
  static const String tmdbImageBase = 'https://image.tmdb.org/t/p';
  
  // Pagination
  static const int itemsPerPage = 20;
  static const int maxConcurrentRequests = 3;
  
  // Cache (Pro version - enhanced cache)
  static const int maxMemoryCacheImages = 200; // Increased for pro version
  static const int maxDiskCacheSizeMB = 1000; // Increased for pro version
  static const int cacheValidityDays = 30;
  static const int staleCacheDays = 7;
  static const int htmlCacheMinutes = 5;
  // Bump this when HTML parsing/selectors change to invalidate old Hive pages
  static const int cacheSchemaVersion = 1;
  
  // Performance
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);
  static const Duration rateLimitDelay = Duration(milliseconds: 350);
  static const Duration debounceDelay = Duration(milliseconds: 300);
  
  // Download (Pro version - enhanced limits)
  static const int maxConcurrentDownloads = 5; // Increased for pro version
  static const int maxDownloadRetries = 5; // More retries for pro version
  
  // Grid Layout
  static const int defaultGridColumns = 2;
  static const int tabletGridColumns = 3;
  static const int desktopGridColumns = 4;
  
  // Search
  static const int maxSearchHistory = 10;
  
  // Local Storage Keys
  static const String keyProStatus = 'pro_status';
  static const String keyThemeMode = 'theme_mode';
  static const String keyGridSize = 'grid_size';
  static const String keySearchHistory = 'search_history';
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyDownloadQuality = 'download_quality';
  static const String keyCacheSize = 'cache_size';
  
  // Hive Box Names
  static const String boxFavorites = 'favorites';
  static const String boxDownloadHistory = 'download_history';
  static const String boxUserPrefs = 'user_prefs';
  static const String boxSubscription = 'subscription_status';
  static const String boxCacheMetadata = 'cache_metadata';
  
  // IAP Product IDs
  static const String iapMonthly = 'pro_monthly';
  static const String iapYearly = 'pro_yearly';
  static const String iapLifetime = 'pro_lifetime';
  
  // Watermark
  static const String watermarkText = 'MovieWalls';
  static const double watermarkOpacity = 0.35;
  static const double watermarkSize = 0.05; // 5% of image height
  
  // Support
  static const String supportEmail = 'support@moviewalls.app';
  static const String privacyPolicyUrl = 'https://moviewalls.app/privacy';
  static const String termsOfServiceUrl = 'https://moviewalls.app/terms';
}

