import '../repositories/auth_repository.dart';

class SetUserLoggedIn {
  final AuthRepository repository;

  SetUserLoggedIn(this.repository);

  Future<void> call(bool isLoggedIn) async {
    await repository.setUserLoggedIn(isLoggedIn);
  }
}