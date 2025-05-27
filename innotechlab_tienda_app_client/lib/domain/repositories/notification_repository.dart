import 'package:dartz/dartz.dart';
import 'package:mi_tienda/core/errors/failures.dart';
import 'package:mi_tienda/domain/entities/app_notification.dart';

abstract class NotificationRepository {
  Future<Either<Failure, List<AppNotification>>> getNotifications();
  Future<Either<Failure, void>> addNotification(AppNotification notification);
  Future<Either<Failure, void>> markNotificationAsRead(String notificationId);
  Future<Either<Failure, void>> clearAllNotifications();
}
