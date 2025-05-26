import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_tienda/core/errors/failures.dart';
import 'package:mi_tienda/core/usecases/usecase.dart';
import 'package:mi_tienda/data/repositories/auth_repository_impl.dart';
import 'package:mi_tienda/domain/repositories/auth_repository.dart';

class UploadProfileImageUseCase implements UseCase<String, UploadProfileImageParams> {
  final AuthRepository repository;
  UploadProfileImageUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(UploadProfileImageParams params) async {
    return await repository.uploadProfileImage(params.filePath);
  }
}

class UploadProfileImageParams {
  final String filePath;
  UploadProfileImageParams({required this.filePath});
}

final uploadProfileImageUseCaseProvider = Provider<UploadProfileImageUseCase>((ref) {
  return UploadProfileImageUseCase(ref.read(authRepositoryProvider));
});