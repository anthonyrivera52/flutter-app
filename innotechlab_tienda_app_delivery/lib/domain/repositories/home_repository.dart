import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/user_status.dart';

abstract class HomeRepository {
  Future<Either<Failure, UserStatus>> getUserConnectionStatus();
  Future<Either<Failure, UserStatus>> goOnline();
  Future<Either<Failure, UserStatus>> goOffline(); // If needed
}