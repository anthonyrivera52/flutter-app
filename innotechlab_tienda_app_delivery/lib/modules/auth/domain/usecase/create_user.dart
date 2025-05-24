import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class CreateUser {
  final AuthRepository repository;

  CreateUser(this.repository);

  Future<void> call(User user) async {
    await repository.saveUser(user);
  }
}