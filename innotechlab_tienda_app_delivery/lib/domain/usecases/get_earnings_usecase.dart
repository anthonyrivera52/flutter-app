import 'package:delivery_app_mvvm/core/error/failures.dart';
import 'package:delivery_app_mvvm/core/usecases/usecase.dart';
import 'package:delivery_app_mvvm/domain/entities/earning.dart';
import 'package:delivery_app_mvvm/domain/repositories/earning_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class GetEarnings implements UseCase<List<Earning>, GetEarningsParams> {
  final EarningRepository repository;

  GetEarnings(this.repository);

  @override
  Future<Either<Failure, List<Earning>>> call(GetEarningsParams params) async {
    return await repository.getEarnings(params.startDate, params.endDate);
  }
}

class GetEarningsParams extends Equatable {
  final DateTime startDate;
  final DateTime endDate;

  const GetEarningsParams({required this.startDate, required this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}