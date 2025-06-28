import 'package:delivery_app_mvvm/core/error/failures.dart';
import 'package:delivery_app_mvvm/domain/entities/earning.dart';
import 'package:dartz/dartz.dart';

abstract class EarningRepository {
  Future<Either<Failure, List<Earning>>> getEarnings(DateTime startDate, DateTime endDate);
  Future<Either<Failure, List<DailyEarning>>> getDailyEarnings(DateTime startDate, DateTime endDate);
}