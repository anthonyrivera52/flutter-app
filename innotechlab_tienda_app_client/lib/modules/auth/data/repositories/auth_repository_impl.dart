import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/localDataSourceImpl.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final LocalDataSource localDataSource;

  AuthRepositoryImpl(this.localDataSource);

  @override
  Future<bool> isUserLoggedIn() async {
    return await localDataSource.isUserLoggedIn();
  }

  @override
  Future<void> setUserLoggedIn(bool isLoggedIn) async {
    await localDataSource.setUserLoggedIn(isLoggedIn);
  }

  @override
  Future<void> saveUser(User user) async {
    await localDataSource.saveUser(UserModel(id: user.id, name: user.name, role: user.role));
  }

  @override
  Future<User?> getUser() async {
    return await localDataSource.getUser();
  }
}