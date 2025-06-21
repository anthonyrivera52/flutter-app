import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/error/exceptions.dart';
import '../../domain/entities/user_status.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_local_data_source.dart';
import '../datasources/home_remote_data_source.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remoteDataSource;
  final HomeLocalDataSource localDataSource;
  // You might also want a NetworkInfo dependency here to check connectivity

  HomeRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, UserStatus>> getUserConnectionStatus() async {
    try {
      // First, try to get status from local cache
      final localStatus = await localDataSource.getLastKnownUserStatus();
      if (localStatus.status == UserConnectionStatus.offline) {
        // If local is offline, try fetching from remote
        final remoteStatus = await remoteDataSource.fetchUserStatusFromApi();
        await localDataSource.cacheUserStatus(remoteStatus);
        return Right(remoteStatus);
      }
      return Right(localStatus);
    } on ServerException {
      return Left(ServerFailure());
    } on CacheException {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, UserStatus>> goOnline() async {
    try {
      final remoteStatus = await remoteDataSource.sendGoOnlineRequest();
      await localDataSource.cacheUserStatus(remoteStatus);
      return Right(remoteStatus);
    } on ServerException {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, UserStatus>> goOffline() async {
    try {
      final remoteStatus = await remoteDataSource.sendGoOfflineRequest();
      await localDataSource.cacheUserStatus(remoteStatus);
      return Right(remoteStatus);
    } on ServerException {
      return Left(ServerFailure());
    }
  }
}