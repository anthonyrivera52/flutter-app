import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mi_tienda/core/errors/failures.dart';
import 'package:mi_tienda/core/usecases/usecase.dart';
import 'package:mi_tienda/domain/entities/order.dart';
import 'package:mi_tienda/domain/repositories/order_repository.dart';

class GetOrderByIdUseCase implements UseCase<Order, GetOrderByIdParams> {
  final OrderRepository repository;

  GetOrderByIdUseCase(this.repository);

  @override
  Future<Either<Failure, Order>> call(GetOrderByIdParams params) async {
    // Corrected to use the existing getOrderDetails method from the repository
    return await repository.getOrderDetails(params.orderId);
  }
}

class GetOrderByIdParams extends Equatable {
  final String orderId;

  const GetOrderByIdParams({required this.orderId});

  @override
  List<Object?> get props => [orderId];
}
