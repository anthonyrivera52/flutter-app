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

class AuthFailure extends Failure {
  final String message;
  const AuthFailure({this.message = 'Cache error occurred'});
}

class NetworkFailure extends Failure {}
