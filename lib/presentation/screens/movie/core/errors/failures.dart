import 'package:equatable/equatable.dart';

/// Base failure class
abstract class Failure extends Equatable {
  final String message;
  
  const Failure(this.message);
  
  @override
  List<Object?> get props => [message];
}

/// Server failure
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Network failure
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Cache failure
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Not found failure
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

/// Rate limit failure
class RateLimitFailure extends Failure {
  const RateLimitFailure(super.message);
}

/// Parse failure
class ParseFailure extends Failure {
  const ParseFailure(super.message);
}

/// Unknown failure
class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}

