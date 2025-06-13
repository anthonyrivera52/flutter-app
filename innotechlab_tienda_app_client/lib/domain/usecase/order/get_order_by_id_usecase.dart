import 'package:dartz/dartz.dart';
import 'package:flutter_app/core/errors/failures.dart';
import 'package:flutter_app/core/usecases/usecase.dart';
import 'package:flutter_app/data/repositories/order_repository_impl.dart';
import 'package:flutter_app/domain/entities/orden.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GetOrderByIdParams {
  final String orderId;
  GetOrderByIdParams({required this.orderId});
}

class GetOrderByIdUseCase extends UseCase<Orden, GetOrderByIdParams> {
  final OrderRepository repository;

  GetOrderByIdUseCase(this.repository);

  @override
  Future<Either<Failure, Orden>> call(GetOrderByIdParams params) async {
    return await repository.getOrderById(params.orderId);
  }
}

final getOrderByIdUseCaseProvider = Provider<GetOrderByIdUseCase>((ref) {
  final orderRepository = ref.watch(orderRepositoryProvider);
  return GetOrderByIdUseCase(orderRepository);
});