import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_tienda/core/errors/failures.dart';
import 'package:mi_tienda/core/usecases/usecase.dart';
import 'package:mi_tienda/data/repositories/auth_repository_impl.dart';
import 'package:mi_tienda/domain/repositories/auth_repository.dart';

class SendOtpUseCase implements UseCase<void, SendOtpParams> {
  final AuthRepository repository;
  SendOtpUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(SendOtpParams params) async {
    return await repository.sendOtp(params.email);
  }
}

class SendOtpParams {
  final String email;
  SendOtpParams({required this.email});
}

final sendOtpUseCaseProvider = Provider<SendOtpUseCase>((ref) {
  return SendOtpUseCase(ref.read(authRepositoryProvider));
});


// // domain/usecases/auth/send_otp_usecase.dart
// import 'package:dartz/dartz.dart';
// import 'package:mi_tienda/core/errors/failures.dart';
// import 'package:mi_tienda/core/usecases/usecase.dart';
// import 'package:mi_tienda/domain/repositories/auth_repository.dart';

// class SendOtpUseCase implements UseCase<void, SendOtpParams> {
//   final AuthRepository repository;
//   SendOtpUseCase(this.repository);

//   @override
//   Future<Either<Failure, void>> call(SendOtpParams params) async {
//     return await repository.sendOtp(params.email);
//   }
// }

// class SendOtpParams {
//   final String email;
//   SendOtpParams({required this.email});
// }

// final sendOtpUseCaseProvider = Provider<SendOtpUseCase>((ref) {
//   return SendOtpUseCase(ref.read(authRepositoryProvider));
// });

// // domain/usecases/auth/verify_otp_usecase.dart
// import 'package:dartz/dartz.dart';
// import 'package:mi_tienda/core/errors/failures.dart';
// import 'package:mi_tienda/core/usecases/usecase.dart';
// import 'package:mi_tienda/domain/entities/user.dart';
// import 'package:mi_tienda/domain/repositories/auth_repository.dart';

// class VerifyOtpUseCase implements UseCase<User, VerifyOtpParams> {
//   final AuthRepository repository;
//   VerifyOtpUseCase(this.repository);

//   @override
//   Future<Either<Failure, User>> call(VerifyOtpParams params) async {
//     return await repository.verifyOtp(params.email, params.otp);
//   }
// }

// class VerifyOtpParams {
//   final String email;
//   final String otp;
//   VerifyOtpParams({required this.email, required this.otp});
// }

// final verifyOtpUseCaseProvider = Provider<VerifyOtpUseCase>((ref) {
//   return VerifyOtpUseCase(ref.read(authRepositoryProvider));
// });