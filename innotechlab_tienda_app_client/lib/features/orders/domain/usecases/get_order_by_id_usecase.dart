import 'package:dartz/dartz.dart';
import 'package:flutter_app/core/errors/failures.dart';
import 'package:flutter_app/core/usecases/usecase.dart';
import 'package:flutter_app/features/orders/data/repositories/order_repository_impl.dart';
import 'package:flutter_app/features/orders/domain/models/order_entity.dart';
import 'package:flutter_app/features/orders/domain/repositories/order_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GetOrderByIdParams {
  final String orderId;
  const GetOrderByIdParams({required this.orderId});
}

class GetOrderByIdUseCase extends UseCase<AppOrder, GetOrderByIdParams> {
  final OrderRepository _repository;
  GetOrderByIdUseCase(this._repository);

  @override
  Future<Either<Failure, AppOrder>> call(GetOrderByIdParams params) =>
      _repository.getOrderById(params.orderId);
}

final getOrderByIdUseCaseProvider = Provider<GetOrderByIdUseCase>((ref) {
  return GetOrderByIdUseCase(ref.watch(orderRepositoryProvider));
});
