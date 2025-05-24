import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class GetUser {
  final AuthRepository repository;

  GetUser(this.repository);

  Future<User?> call() async {
    return await repository.getUser();
  }
}