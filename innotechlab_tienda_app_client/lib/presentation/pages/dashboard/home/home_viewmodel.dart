import 'package:equatable/equatable.dart';
import 'package:flutter_app/domain/entities/product.dart';

/// Represents the state of the Home screen.
/// It is immutable and used with the HomeNotifier.
class HomeState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final List<Product> products;

  const HomeState({
    this.isLoading = false,
    this.errorMessage,
    this.products = const [],
  });

  /// Creates a new instance of HomeState with updated values.
  HomeState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<Product>? products,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // Allows setting null
      products: products ?? this.products,
    );
  }

  @override
  List<Object?> get props => [isLoading, errorMessage, products];
}
