// lib/domain/usecases/sign_up_user.dart
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class SignUpUser {
  final AuthRepository repository;

  SignUpUser(this.repository);

  Future<Either<Failure, AuthUser>> call(String email, String password) async {
    return await repository.signUp(email, password);
  }
}