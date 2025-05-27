import 'package:dartz/dartz.dart';
import 'package:mi_tienda/core/errors/exceptions.dart';
import 'package:mi_tienda/core/errors/failures.dart';
import 'package:mi_tienda/data/datasources/notification_local_datasource.dart';
import 'package:mi_tienda/domain/entities/app_notification.dart';
import 'package:mi_tienda/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationLocalDataSource localDataSource;

  NotificationRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<AppNotification>>> getNotifications() async {
    try {
      final notifications = await localDataSource.getNotifications();
      return Right(notifications);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> addNotification(AppNotification notification) async {
    try {
      final currentNotifications = await localDataSource.getNotifications();
      final updatedNotifications = [notification, ...currentNotifications];
      await localDataSource.saveNotifications(updatedNotifications);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> markNotificationAsRead(String notificationId) async {
    try {
      final currentNotifications = await localDataSource.getNotifications();
      final updatedNotifications = currentNotifications.map((n) {
        if (n.id == notificationId) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();
      await localDataSource.saveNotifications(updatedNotifications);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> clearAllNotifications() async {
    try {
      await localDataSource.clearNotifications();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}
