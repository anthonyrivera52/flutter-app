import 'package:delivery_app_mvvm/domain/entities/earning.dart';

class EarningModel extends Earning {
  const EarningModel({
    required super.date,
    required super.amount,
    required super.ordersCount,
    required super.onlineHours,
  });

  factory EarningModel.fromJson(Map<String, dynamic> json) {
    return EarningModel(
      date: json['date'] as DateTime, // Assuming date is a String like 'YYYY-MM-DD'
      amount: (json['amount'] as num).toDouble(),
      ordersCount: json['orders_count'] as int,
      onlineHours: (json['online_hours'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'amount': amount,
      'orders_count': ordersCount,
      'online_hours': onlineHours,
    };
  }
}

class DailyEarningModel extends DailyEarning {
  const DailyEarningModel({
    required super.date,
    required super.amount,
  });

  factory DailyEarningModel.fromJson(Map<String, dynamic> json) {
    return DailyEarningModel(
      date: json['date'] as DateTime,
      amount: (json['amount'] as num).toDouble(),
    );
  }
}