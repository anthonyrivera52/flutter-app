import 'package:dartz/dartz.dart';
import 'package:mi_tienda/core/errors/failures.dart';
import 'package:mi_tienda/domain/entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> signIn(String email, String password);
    Future<Either<Failure, User>> signUp({ // <-- Añade este método
    required String email,
    required String password,
    String? displayName,
  });
  Future<Either<Failure, User?>> getCurrentUser();
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, void>> sendOtp(String email); // NUEVO
  Future<Either<Failure, User>> verifyOtp(String email, String otp); // NUEVO
  Future<Either<Failure, User>> updateUserProfile({String? username, String? avatarUrl}); // NUEVO
  Future<Either<Failure, String>> uploadProfileImage(String filePath); // NUEVO (retorna URL de la imagen)
}