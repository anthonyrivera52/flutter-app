import '../repositories/auth_repository.dart';

class CheckOnboardingStatus {
  final AuthRepository repository;

  CheckOnboardingStatus(this.repository);

  Future<bool> call() async {
    return await repository.isOnboardingCompleted();
  }
}