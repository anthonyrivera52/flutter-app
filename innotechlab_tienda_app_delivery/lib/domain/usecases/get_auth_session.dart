// lib/domain/usecases/get_auth_session.dart
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class GetAuthSession {
  final AuthRepository repository;

  GetAuthSession(this.repository);

  Future<Either<Failure, AuthUser?>> call() async {
    return await repository.getSession();
  }
}