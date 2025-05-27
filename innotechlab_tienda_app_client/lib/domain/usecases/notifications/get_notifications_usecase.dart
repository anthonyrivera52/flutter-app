import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_tienda/core/errors/failures.dart';
import 'package:mi_tienda/core/usecases/usecase.dart';
import 'package:mi_tienda/domain/entities/app_notification.dart';
import 'package:mi_tienda/domain/repositories/notification_repository.dart';

class GetNotificationsUseCase implements UseCase<List<AppNotification>, NoParams> {
  final NotificationRepository repository;

  GetNotificationsUseCase(this.repository);

  @override
  Future<Either<Failure, List<AppNotification>>> call(NoParams params) async {
    return await repository.getNotifications();
  }
}
