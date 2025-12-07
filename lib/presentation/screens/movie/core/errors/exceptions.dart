/// Base exception class
class AppException implements Exception {
  final String message;
  
  AppException(this.message);
  
  @override
  String toString() => message;
}

/// Server exception
class ServerException extends AppException {
  ServerException(super.message);
}

/// Network exception
class NetworkException extends AppException {
  NetworkException(super.message);
}

/// Cache exception
class CacheException extends AppException {
  CacheException(super.message);
}

/// Not found exception
class NotFoundException extends AppException {
  NotFoundException(super.message);
}

/// Rate limit exception
class RateLimitException extends AppException {
  RateLimitException(super.message);
}

/// Parse exception
class ParseException extends AppException {
  ParseException(super.message);
}

