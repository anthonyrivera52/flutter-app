// lib/core/error/failures.dart
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure([this.properties = const <dynamic>[]]);

  final List properties;

  @override
  List<Object?> get props => properties;
}

// General failures
class ServerFailure extends Failure {}
class CacheFailure extends Failure {}

// New: Authentication failures
class AuthFailure extends Failure {
  final String message;
  AuthFailure({this.message = 'Authentication failed.'}) : super([message]);
}