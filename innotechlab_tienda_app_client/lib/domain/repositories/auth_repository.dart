import 'package:dartz/dartz.dart';
import 'package:mi_tienda/core/errors/failures.dart';
import 'package:mi_tienda/domain/entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> signIn({
    required String email,
    required String password,
  });
  Future<Either<Failure, User>> signUp({
    required String email,
    required String password,
    String? displayName,
  });
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, User>> getCurrentUser();
  Stream<User?> get authStateChanges;
}
