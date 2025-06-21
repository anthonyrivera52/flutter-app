import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/user_status.dart';
import '../repositories/home_repository.dart';

class GoOffline { // <--- NEW USE CASE
  final HomeRepository repository;

  GoOffline(this.repository);

  Future<Either<Failure, UserStatus>> call() async {
    return await repository.goOffline();
  }
}