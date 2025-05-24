import 'package:flutter_app/modules/onboarding/data/datasource/local_datasource.dart';
import 'package:flutter_app/modules/onboarding/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final LocalDataSource localDataSource;

  AuthRepositoryImpl(this.localDataSource);

  @override
  Future<bool> isOnboardingCompleted() async {
    return await localDataSource.isOnboardingCompleted();
  }

  @override
  Future<void> setOnboardingCompleted() async {
    await localDataSource.setOnboardingCompleted();
  }

}