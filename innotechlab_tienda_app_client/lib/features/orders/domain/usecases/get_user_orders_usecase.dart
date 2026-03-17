import 'package:dartz/dartz.dart';
import 'package:flutter_app/core/errors/failures.dart';
import 'package:flutter_app/core/usecases/usecase.dart';
import 'package:flutter_app/features/orders/data/datasources/order_remote_datasource.dart';
import 'package:flutter_app/features/orders/data/repositories/order_repository_impl.dart';
import 'package:flutter_app/features/orders/domain/repositories/order_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GetUserOrdersParams {
  final String? cursor;
  final int limit;
  const GetUserOrdersParams({this.cursor, this.limit = 10});
}

class GetUserOrdersUseCase
    extends UseCase<PaginatedOrders, GetUserOrdersParams> {
  final OrderRepository _repository;
  GetUserOrdersUseCase(this._repository);

  @override
  Future<Either<Failure, PaginatedOrders>> call(GetUserOrdersParams params) =>
      _repository.getUserOrders(cursor: params.cursor, limit: params.limit);
}

final getUserOrdersUseCaseProvider = Provider<GetUserOrdersUseCase>((ref) {
  return GetUserOrdersUseCase(ref.watch(orderRepositoryProvider));
});
