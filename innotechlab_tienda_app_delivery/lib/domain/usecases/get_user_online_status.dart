import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/user_status.dart';
import '../repositories/home_repository.dart';

class GetUserOnlineStatus {
  final HomeRepository repository;

  GetUserOnlineStatus(this.repository);

  Future<Either<Failure, UserStatus>> call() async {
    return await repository.getUserConnectionStatus();
  }
}

class GoOnline {
  final HomeRepository repository;

  GoOnline(this.repository);

  Future<Either<Failure, UserStatus>> call() async {
    return await repository.goOnline();
  }
}