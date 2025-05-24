import 'package:flutter_app/modules/onboarding/domain/usecase/check_onboarding_status.dart';
import 'package:flutter_app/modules/onboarding/domain/usecase/set_onboarding_completed.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../modules/auth/data/datasources/localDataSourceImpl.dart';
import '../../modules/auth/data/repositories/auth_repository_impl.dart';
import '../../modules/auth/domain/repositories/auth_repository.dart';
import '../../modules/auth/domain/usecase/check_login_status.dart';
import '../../modules/auth/domain/usecase/create_user.dart';
import '../../modules/auth/domain/usecase/get_user.dart';

final sl = GetIt.instance;

final checkOnboardingStatusProvider = Provider<CheckOnboardingStatus>((ref) => sl<CheckOnboardingStatus>());
final checkLoginStatusProvider = Provider<CheckLoginStatus>((ref) => sl<CheckLoginStatus>());
final setOnboardingCompletedProvider = Provider<SetOnboardingCompleted>((ref) => sl<SetOnboardingCompleted>());
final getUserProvider = Provider<GetUser>((ref) => sl<GetUser>());
final createUserProvider = Provider<CreateUser>((ref) => sl<CreateUser>());
final authRepositoryProvider = Provider<AuthRepository>((ref) => sl<AuthRepository>());

Future<void> init() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPreferences);
  sl.registerLazySingleton<LocalDataSource>(() => LocalDataSourceImpl(sl()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton<CheckOnboardingStatus>(() => CheckOnboardingStatus(sl()));
  sl.registerLazySingleton<CheckLoginStatus>(() => CheckLoginStatus(sl()));
  sl.registerLazySingleton<SetOnboardingCompleted>(() => SetOnboardingCompleted(sl()));
  sl.registerLazySingleton<GetUser>(() => GetUser(sl()));
  sl.registerLazySingleton<CreateUser>(() => CreateUser(sl()));
}