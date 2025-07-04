// lib/viewmodel/earning_viewmodel.dart
import 'package:delivery_app_mvvm/domain/entities/earning.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Assume you have these models// Or domain/entities/daily_earning.dart

class EarningViewModel extends ChangeNotifier {
  List<Earning> _earnings = [];
  List<DailyEarning> _dailyEarnings = [];
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;
  String? _errorMessage;

  List<Earning> get earnings => _earnings;
  List<DailyEarning> get dailyEarnings => _dailyEarnings;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Private helper methods for ViewModel's internal date calculations
  DateTime _findMondayOfWeek(DateTime date) {
    int daysToSubtract = date.weekday - 1;
    DateTime monday = date.subtract(Duration(days: daysToSubtract));
    return DateTime(monday.year, monday.month, monday.day);
  }

  DateTime _findSundayOfWeek(DateTime date) {
    DateTime monday = _findMondayOfWeek(date);
    DateTime sunday = monday.add(const Duration(days: 6));
    return DateTime(sunday.year, sunday.month, sunday.day);
  }

  Future<void> fetchEarningsForWeekOf(DateTime dateInWeek) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // Notify UI about loading state

    try {
      _startDate = _findMondayOfWeek(dateInWeek);
      _endDate = _findSundayOfWeek(dateInWeek);

      // Simulate API call or data fetching based on _startDate and _endDate
      // Replace with your actual data fetching logic
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

      // Dummy data for demonstration
      _earnings = _generateDummyEarnings(_startDate, _endDate);
      _dailyEarnings = _generateDummyDailyEarnings(_startDate, _endDate);

      _errorMessage = null;
    } catch (e) {
      _errorMessage = "Failed to load earnings: $e";
      _earnings = [];
      _dailyEarnings = [];
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify UI about data loaded/error state
    }
  }

  // Add dummy data generation for testing
  List<Earning> _generateDummyEarnings(DateTime start, DateTime end) {
    List<Earning> list = [];
    DateTime current = start;
    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      // Simulate some earnings for each day
      double amount = (current.day * 10.0 + current.month + 50).toDouble(); // Just some varied amount
      int orders = current.day % 5 + 1; // 1 to 5 orders
      list.add(Earning(
        date: current,
        amount: amount,
        ordersCount: orders,
        onlineHours: (current.day % 8) + 4, // 4 to 11 hours
      ));
      current = current.add(const Duration(days: 1));
    }
    return list;
  }

  List<DailyEarning> _generateDummyDailyEarnings(DateTime start, DateTime end) {
    List<DailyEarning> list = [];
    DateTime current = start;
    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      double amount = (current.day * 10.0 + current.month + 50).toDouble();
      list.add(DailyEarning(
        date: current,
        amount: amount,
      ));
      current = current.add(const Duration(days: 1));
    }
    return list;
  }


  String getFormattedWeekRange() {
    if (_startDate == null || _endDate == null) {
      return 'Cargando semana...';
    }
    String startDay = DateFormat('dd').format(_startDate);
    String endDay = DateFormat('dd').format(_endDate);
    String month = DateFormat('MMM').format(_endDate); // Month of end date
    String year = DateFormat('yyyy').format(_endDate);
    return '$startDay - $endDay $month, $year';
  }

  double getTotalAmount() {
    return _earnings.fold(0.0, (sum, item) => sum + item.amount);
  }

  int getTotalOrders() {
    return _earnings.fold(0, (sum, item) => sum + item.ordersCount);
  }

  double getTotalOnlineHours() {
    return _earnings.fold(0.0, (sum, item) => sum + item.onlineHours);
  }

  // Method to handle setting to last 30 days (if you decide to bring it back)
  void setDateRangeToLast30Days() {
    _endDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    _startDate = _endDate.subtract(const Duration(days: 29));
    // You'll need to refetch data for this range here
    // _fetchDataForRange(_startDate, _endDate); // Implement a generic fetch
    notifyListeners();
  }

  // Placeholder models - create these files in your `model` or `domain/entities` directory
  // lib/model/earning_model.dart
  // class Earning {
  //   final String date;
  //   final double amount;
  //   final int ordersCount;
  //   final double onlineHours;
  //   Earning({required this.date, required this.amount, required this.ordersCount, required this.onlineHours});
  // }

  // lib/model/daily_earning_model.dart
  // class DailyEarning {
  //   final String date;
  //   final double amount;
  //   DailyEarning({required this.date, required this.amount});
  // }
}