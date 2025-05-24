import 'package:shared_preferences/shared_preferences.dart';

abstract class LocalDataSource {
  Future<bool> isOnboardingCompleted();
  Future<void> setOnboardingCompleted();
}

class LocalDataSourceImpl implements LocalDataSource {
  final SharedPreferences sharedPreferences;

  LocalDataSourceImpl(this.sharedPreferences);

  @override
  Future<bool> isOnboardingCompleted() async {
    return sharedPreferences.getBool('onboarding_completed') ?? false;
  }

  @override
  Future<void> setOnboardingCompleted() async {
    await sharedPreferences.setBool('onboarding_completed', true);
  }
}