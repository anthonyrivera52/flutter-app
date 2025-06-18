import 'package:dartz/dartz.dart';
import 'package:flutter_app/core/errors/failures.dart';
import 'package:flutter_app/core/usecases/usecase.dart';
import 'package:flutter_app/domain/entities/orden.dart';
import 'package:flutter_app/domain/repositories/orden_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GetUserOrdersUseCase implements UseCase<List<Orden>, NoParams> {
  final OrdenRepository repository;
  GetUserOrdersUseCase(this.repository);

  @override
  Future<Either<Failure, List<Orden>>> call(NoParams params) async {
    return await repository.getUserOrders();
  }
}

final getUserOrdersUseCaseProvider = Provider<GetUserOrdersUseCase>((ref) {
  return GetUserOrdersUseCase(ref.read(orderRepositoryProvider));
});
