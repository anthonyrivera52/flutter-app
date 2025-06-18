
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_app/core/errors/failures.dart';

/// Abstract class to define a contract for all use cases in the application.
/// T represents the return type (e.g., [List<Product>], [User], [void]).
/// P represents the parameters type (e.g., [GetProductByIdParams], [NoParams]).
abstract class UseCase<T, P> {
  Future<Either<Failure, T>> call(P params);
}

/// Class to be used when a UseCase does not require any parameters.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
