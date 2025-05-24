import '../repositories/auth_repository.dart';

class CheckLoginStatus {
  final AuthRepository repository;

  CheckLoginStatus(this.repository);

  Future<bool> call() async {
    return await repository.isUserLoggedIn();
  }
}