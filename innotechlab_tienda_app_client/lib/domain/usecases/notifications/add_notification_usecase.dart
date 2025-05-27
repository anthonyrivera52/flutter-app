import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_tienda/core/errors/failures.dart';
import 'package:mi_tienda/core/usecases/usecase.dart';
import 'package:mi_tienda/domain/entities/app_notification.dart';
import 'package:mi_tienda/domain/repositories/notification_repository.dart';

class AddNotificationUseCase implements UseCase<void, AddNotificationParams> {
  final NotificationRepository repository;

  AddNotificationUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(AddNotificationParams params) async {
    return await repository.addNotification(params.notification);
  }
}

class AddNotificationParams {
  final AppNotification notification;
  AddNotificationParams(this.notification);
}
