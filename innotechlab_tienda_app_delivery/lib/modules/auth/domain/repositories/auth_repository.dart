import '../entities/user.dart';

abstract class AuthRepository {
  Future<bool> isUserLoggedIn();
  Future<void> setUserLoggedIn(bool isLoggedIn);
  Future<void> saveUser(User user);
  Future<User?> getUser();
}