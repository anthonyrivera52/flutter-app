

abstract class AuthRepository {
  Future<bool> isOnboardingCompleted();
  Future<void> setOnboardingCompleted();
}