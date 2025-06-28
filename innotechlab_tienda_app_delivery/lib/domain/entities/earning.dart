import 'package:equatable/equatable.dart';

class Earning extends Equatable {
  final String date;
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

class DailyEarning extends Equatable {
  final DateTime date;
  final double amount;

  const DailyEarning({required this.date, required this.amount});

  @override
  List<Object?> get props => [date, amount];
}