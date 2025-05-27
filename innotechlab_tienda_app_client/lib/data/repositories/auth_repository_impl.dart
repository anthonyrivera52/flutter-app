import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_tienda/core/errors/exceptions.dart';
import 'package:mi_tienda/core/errors/failures.dart';
import 'package:mi_tienda/domain/entities/user.dart';
import 'package:mi_tienda/domain/repositories/auth_repository.dart';
import 'package:mi_tienda/data/datasources/auth_remote_datasource.dart';
import 'package:mi_tienda/core/network/network_info.dart';
import 'package:mi_tienda/service_locator.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, User>> signIn({
    required String email,
    required String password,
  }) async {
    if (await networkInfo.isConnected()) {
      try {
        final userModel = await remoteDataSource.signIn(email: email, password: password);
        return Right(userModel.toEntity());
      } on ServerException catch (e) {
        return Left(AuthFailure(e.message));
      }
    } else {
      return Left(NetworkFailure('No hay conexión a internet para iniciar sesión.'));
    }
  }

  @override
  Future<Either<Failure, User>> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (await networkInfo.isConnected()) {
      try {
        final userModel = await remoteDataSource.signUp(
          email: email,
          password: password,
          displayName: displayName,
        );
        return Right(userModel.toEntity());
      } on ServerException catch (e) {
        return Left(AuthFailure(e.message));
      }
    } else {
      return Left(NetworkFailure('No hay conexión a internet para registrarse.'));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    if (await networkInfo.isConnected()) {
      try {
        await remoteDataSource.signOut();
        return const Right(null);
      } on ServerException catch (e) {
        return Left(AuthFailure(e.message));
      }
    } else {
      return Left(NetworkFailure('No hay conexión a internet para cerrar sesión.'));
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    // Para esta operación, podríamos no requerir conexión activa si el usuario ya está en caché
    // o si el cliente de Supabase puede devolver un usuario de sesión local.
    // Sin embargo, para fines de consistencia con las otras operaciones de red, lo mantendremos.
    // Una mejora futura podría ser verificar primero la caché.
    if (await networkInfo.isConnected()) {
      try {
        final userModel = await remoteDataSource.getCurrentUser();
        return Right(userModel.toEntity());
      } on ServerException catch (e) {
        return Left(AuthFailure(e.message));
      }
    } else {
      return Left(NetworkFailure('No hay conexión a internet para obtener el usuario actual.'));
    }
  }

  @override
  Stream<User?> get authStateChanges {
    return remoteDataSource.authStateChanges.map((userModel) => userModel?.toEntity());
  }
}
