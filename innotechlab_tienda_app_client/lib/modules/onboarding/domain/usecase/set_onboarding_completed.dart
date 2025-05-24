import '../repositories/auth_repository.dart';

class SetOnboardingCompleted {
  final AuthRepository repository;

  SetOnboardingCompleted(this.repository);

  Future<void> call() async {
    await repository.setOnboardingCompleted();
  }
}