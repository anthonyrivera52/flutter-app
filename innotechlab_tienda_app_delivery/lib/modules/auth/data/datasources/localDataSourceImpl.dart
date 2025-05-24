import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

abstract class LocalDataSource {
  Future<bool> isUserLoggedIn();
  Future<void> setUserLoggedIn(bool isLoggedIn);
  Future<void> saveUser(UserModel user);
  Future<UserModel?> getUser();
}

class LocalDataSourceImpl implements LocalDataSource {
  final SharedPreferences sharedPreferences;

  LocalDataSourceImpl(this.sharedPreferences);

  @override
  Future<bool> isUserLoggedIn() async {
    return sharedPreferences.getBool('is_logged_in') ?? false;
  }

  @override
  Future<void> setUserLoggedIn(bool isLoggedIn) async {
    await sharedPreferences.setBool('is_logged_in', isLoggedIn);
  }

  @override
  Future<void> saveUser(UserModel user) async {
    await sharedPreferences.setString('user_id', user.id);
    await sharedPreferences.setString('user_name', user.name);
    await sharedPreferences.setString('user_role', user.role);
  }

  @override
  Future<UserModel?> getUser() async {
    final id = sharedPreferences.getString('user_id');
    final name = sharedPreferences.getString('user_name');
    final role = sharedPreferences.getString('user_role');
    if (id != null && name != null && role != null) {
      return UserModel(id: id, name: name, role: role);
    }
    return null;
  }
}