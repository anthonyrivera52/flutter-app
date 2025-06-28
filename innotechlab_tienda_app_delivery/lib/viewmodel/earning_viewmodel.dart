
import 'package:delivery_app_mvvm/domain/entities/earning.dart';
import 'package:delivery_app_mvvm/domain/usecases/get_daily_earnings.dart';
import 'package:delivery_app_mvvm/domain/usecases/get_earnings_usecase.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class EarningViewModel extends ChangeNotifier {
  final GetEarnings getEarnings;
  final GetDailyEarnings getDailyEarnings;

  EarningViewModel({
    required this.getEarnings,
    required this.getDailyEarnings,
  });

  List<Earning> _earnings = [];
  List<Earning> get earnings => _earnings;

  List<DailyEarning> _dailyEarnings = [];
  List<DailyEarning> get dailyEarnings => _dailyEarnings;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Selected date range for earnings
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 6));
  DateTime _endDate = DateTime.now();

  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;

  Future<void> fetchEarnings(DateTime start, DateTime end) async {
    _isLoading = true;
    _errorMessage = null;
    _startDate = start;
    _endDate = end;
    notifyListeners();

    final result = await getEarnings(GetEarningsParams(startDate: start, endDate: end));
    result.fold(
      (failure) {
        _errorMessage = "Error al cargar ganancias.";
        _isLoading = false;
        notifyListeners();
      },
      (data) {
        _earnings = data;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> fetchDailyEarnings(DateTime start, DateTime end) async {
    _isLoading = true;
    _errorMessage = null;
    _startDate = start;
    _endDate = end;
    notifyListeners();

    final result = await getDailyEarnings(GetDailyEarningsParams(startDate: start, endDate: end));
    result.fold(
      (failure) {
        _errorMessage = "Error al cargar ganancias diarias.";
        _isLoading = false;
        notifyListeners();
      },
      (data) {
        _dailyEarnings = data;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // Helper to format dates for display (e.g., "Jun 19 - Jun 25")
  String getFormattedDateRange() {
    final format = DateFormat('MMM dd');
    return '${format.format(_startDate)} - ${format.format(_endDate)}';
  }

  // You might want methods to change the date range (e.g., last 7 days, last 30 days)
  void setDateRangeToLast7Days() {
    _endDate = DateTime.now();
    _startDate = _endDate.subtract(const Duration(days: 6));
    fetchEarnings(_startDate, _endDate);
    fetchDailyEarnings(_startDate, _endDate);
  }

  void setDateRangeToLast30Days() {
    _endDate = DateTime.now();
    _startDate = _endDate.subtract(const Duration(days: 29));
    fetchEarnings(_startDate, _endDate);
    fetchDailyEarnings(_startDate, _endDate);
  }

  // Calculate total earnings, orders, and online hours from fetched data
  double getTotalAmount() {
    return _earnings.fold(0.0, (sum, item) => sum + item.amount);
  }

  int getTotalOrders() {
    return _earnings.fold(0, (sum, item) => sum + item.ordersCount);
  }

  int getTotalOnlineHours() {
    return _earnings.fold(0, (sum, item) => sum + item.onlineHours);
  }
}