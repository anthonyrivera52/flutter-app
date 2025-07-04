import 'package:equatable/equatable.dart';

class Earning extends Equatable {
  final DateTime date;
  final double amount;
  final int ordersCount;
  final int onlineHours;

  const Earning({
    required this.date,
    required this.amount,
    required this.ordersCount,
    required this.onlineHours,
  });

  @override
  List<Object?> get props => [date, amount, ordersCount, onlineHours];
}

// domain/entities/earning.dart
class DailyEarning extends Equatable {
  final DateTime date; // Or DateTime
  final double amount;
  final int ordersCount; // Added
  final double onlineHours; // Added

  const DailyEarning({
    required this.date,
    required this.amount,
    this.ordersCount = 0, // Default if not always present
    this.onlineHours = 0.0, // Default if not always present
  });

  @override
  List<Object?> get props => [date, amount, ordersCount, onlineHours];
}