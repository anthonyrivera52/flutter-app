// lib/domain/repositories/auth_repository.dart
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/auth_user.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthUser>> signIn(String email, String password);
  Future<Either<Failure, AuthUser>> signUp(String email, String password);
  Future<Either<Failure, void>> signOut(); // void for success, Failure for error
  Future<Either<Failure, AuthUser?>> getSession(); // Returns AuthUser or null if not authenticated
  Stream<AuthUser?> get authStateChanges; // Stream for real-time auth state
}