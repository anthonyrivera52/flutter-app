// lib/domain/usecases/sign_in_user.dart
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class SignInUser {
  final AuthRepository repository;

  SignInUser(this.repository);

  Future<Either<Failure, AuthUser>> call(String email, String password) async {
    return await repository.signIn(email, password);
  }
}