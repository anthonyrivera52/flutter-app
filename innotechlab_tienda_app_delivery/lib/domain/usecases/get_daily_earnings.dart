import 'package:delivery_app_mvvm/core/error/failures.dart';
import 'package:delivery_app_mvvm/core/usecases/usecase.dart';
import 'package:delivery_app_mvvm/domain/entities/earning.dart';
import 'package:delivery_app_mvvm/domain/repositories/earning_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class GetDailyEarnings implements UseCase<List<DailyEarning>, GetDailyEarningsParams> {
  final EarningRepository repository;

  GetDailyEarnings(this.repository);

  @override
  Future<Either<Failure, List<DailyEarning>>> call(GetDailyEarningsParams params) async {
    return await repository.getDailyEarnings(params.startDate, params.endDate);
  }
}

class GetDailyEarningsParams extends Equatable {
  final DateTime startDate;
  final DateTime endDate;

  const GetDailyEarningsParams({required this.startDate, required this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}