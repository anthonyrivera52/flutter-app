

import 'package:dartz/dartz.dart';
import 'package:delivery_app_mvvm/core/error/exceptions.dart';
import 'package:delivery_app_mvvm/core/error/failures.dart';
import 'package:delivery_app_mvvm/data/datasources/auth_remote_data_source.dart';
import 'package:delivery_app_mvvm/domain/entities/auth_user.dart';
import 'package:delivery_app_mvvm/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, AuthUser>> signIn(String email, String password) async {
    try {
      final user = await remoteDataSource.signInWithEmailPassword(email, password);
      return Right(user as AuthUser);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(AuthFailure(message: 'An unexpected error occurred.'));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> signUp(String email, String password) async {
    try {
      final user = await remoteDataSource.signUpWithEmailPassword(email, password);
      return Right(user as AuthUser);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(AuthFailure(message: 'An unexpected error occurred.'));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      return const Right(null); // Use null for void success
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(AuthFailure(message: 'An unexpected error occurred.'));
    }
  }

  @override
  Future<Either<Failure, AuthUser?>> getSession() async {
    try {
      final session = remoteDataSource.getCurrentSession();
      if (session != null && session.user != null) {
        return Right(AuthUser(
          uid: session.user.id,
          email: session.user.email,
        ));
      }
      return const Right(null); // No active session
    } catch (e) {
      return Left(AuthFailure(message: 'Error getting session: ${e.toString()}'));
    }
  }

  @override
  Stream<AuthUser?> get authStateChanges {
    return remoteDataSource.authStateChanges.map((event) {
      if (event.session?.user != null) {
        return AuthUser(
          uid: event.session!.user.id,
          email: event.session!.user.email,
        );
      }
      return null; // User logged out or no session
    });
  }
}