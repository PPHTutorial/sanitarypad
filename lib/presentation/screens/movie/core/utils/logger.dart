import 'package:logger/logger.dart';

/// Custom logger for the application
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );
  
  static final Logger _loggerNoStack = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      colors: true,
      printEmojis: true,
      printTime: false,
    ),
  );
  
  /// Log debug message
  static void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }
  
  /// Log info message
  static void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }
  
  /// Log warning message
  static void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }
  
  /// Log error message
  static void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
  
  /// Log fatal message
  static void f(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
  
  /// Log API request
  static void apiRequest(String method, String url, {Map<String, dynamic>? headers}) {
    _loggerNoStack.d('🌐 API $method: $url');
    if (headers != null && headers.isNotEmpty) {
      _loggerNoStack.d('📋 Headers: $headers');
    }
  }
  
  /// Log API response
  static void apiResponse(int statusCode, String url, {dynamic data}) {
    if (statusCode >= 200 && statusCode < 300) {
      _loggerNoStack.i('✅ Response [$statusCode]: $url');
    } else {
      _loggerNoStack.w('⚠️ Response [$statusCode]: $url');
    }
  }
  
  /// Log API error
  static void apiError(String url, dynamic error, [StackTrace? stackTrace]) {
    _logger.e('❌ API Error: $url', error: error, stackTrace: stackTrace);
  }
  
  /// Log scraping action
  static void scraping(String action, {String? details}) {
    _loggerNoStack.d('🔍 Scraping: $action${details != null ? ' - $details' : ''}');
  }
  
  /// Log cache action
  static void cache(String action, {String? key}) {
    _loggerNoStack.d('💾 Cache: $action${key != null ? ' - $key' : ''}');
  }
  
  /// Log navigation
  static void navigation(String route) {
    _loggerNoStack.i('🧭 Navigate: $route');
  }
  
  /// Log download
  static void download(String action, {String? details}) {
    _loggerNoStack.i('⬇️ Download: $action${details != null ? ' - $details' : ''}');
  }
}

