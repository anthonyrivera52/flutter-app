import 'package:delivery_app_mvvm/core/error/exceptions.dart';
import 'package:delivery_app_mvvm/core/error/failures.dart';
import 'package:delivery_app_mvvm/data/datasources/earning_remote_datasource.dart';
import 'package:delivery_app_mvvm/domain/entities/earning.dart';
import 'package:delivery_app_mvvm/domain/repositories/earning_repository.dart';
import 'package:dartz/dartz.dart';

class EarningRepositoryImpl implements EarningRepository {
  final EarningRemoteDataSource earningRemoteDataSource;

  EarningRepositoryImpl({required this.earningRemoteDataSource});

  @override
  Future<Either<Failure, List<Earning>>> getEarnings(DateTime startDate, DateTime endDate) async {
    try {
      final earningModels = await earningRemoteDataSource.getEarnings(startDate, endDate);
      return Right(earningModels);
    } on ServerException catch (e) {
      return Left(ServerFailure());
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<DailyEarning>>> getDailyEarnings(DateTime startDate, DateTime endDate) async {
    try {
      final dailyEarningModels = await earningRemoteDataSource.getDailyEarnings(startDate, endDate);
      return Right(dailyEarningModels);
    } on ServerException catch (e) {
      return Left(ServerFailure());
    } catch (e) {
      return Left(ServerFailure());
    }
  }
}