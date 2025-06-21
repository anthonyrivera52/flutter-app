// lib/core/error/exceptions.dart
class ServerException implements Exception {}
class CacheException implements Exception {}

// New: Authentication exception
class AuthException implements Exception {
  final String message;
  AuthException(String s, {this.message = 'Authentication error'});
}