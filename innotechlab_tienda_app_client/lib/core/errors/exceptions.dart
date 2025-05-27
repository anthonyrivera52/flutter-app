class ServerException implements Exception {
  final String message;
  ServerException(this.message);
}

class CacheException implements Exception {
  final String message;
  CacheException(this.message);
}
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
}
class InvalidInputException implements Exception {
  final String message;
  InvalidInputException(this.message);
}
class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
}
class NotFoundException implements Exception {
  final String message;
  NotFoundException(this.message);
}
class ConflictException implements Exception {
  final String message;
  ConflictException(this.message);
}
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
}
class UnknownException implements Exception {
  final String message;
  UnknownException(this.message);
}
class AuthenticationException implements Exception {
  final String message;
  AuthenticationException(this.message);
}
class PermissionDeniedException implements Exception {
  final String message;
  PermissionDeniedException(this.message);
}
class RateLimitExceededException implements Exception {
  final String message;
  RateLimitExceededException(this.message);
}
class ServiceUnavailableException implements Exception {
  final String message;
  ServiceUnavailableException(this.message);
}
class BadRequestException implements Exception {
  final String message;
  BadRequestException(this.message);
}
class InternalServerErrorException implements Exception {
  final String message;
  InternalServerErrorException(this.message);
}
class UnprocessableEntityException implements Exception {
  final String message;
  UnprocessableEntityException(this.message);
}
class GatewayTimeoutException implements Exception {
  final String message;
  GatewayTimeoutException(this.message);
}
class PreconditionFailedException implements Exception {
  final String message;
  PreconditionFailedException(this.message);
}