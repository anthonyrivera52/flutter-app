import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_tienda/core/errors/failures.dart';
import 'package:mi_tienda/core/usecases/usecase.dart';
import 'package:mi_tienda/domain/entities/user.dart';
import 'package:mi_tienda/domain/repositories/auth_repository.dart';
import 'package:mi_tienda/service_locator.dart';

class UpdateUserProfileUseCase implements UseCase<User, UpdateUserProfileParams> {
  final AuthRepository repository;
  UpdateUserProfileUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(UpdateUserProfileParams params) async {
    return await repository.updateUserProfile(
      username: params.username,
      avatarUrl: params.avatarUrl,
    );
  }
}

class UpdateUserProfileParams {
  final String? username;
  final String? avatarUrl;
  UpdateUserProfileParams({this.username, this.avatarUrl});
}

final updateUserProfileUseCaseProvider = Provider<UpdateUserProfileUseCase>((ref) {
  return UpdateUserProfileUseCase(ref.read(authRepositoryProvider));
});