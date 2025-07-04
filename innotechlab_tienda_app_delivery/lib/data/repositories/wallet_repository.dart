// Example: lib/data/repositories/wallet_repository.dart
import 'package:delivery_app_mvvm/domain/entities/transaction.dart';
import 'package:delivery_app_mvvm/domain/entities/bank_account.dart';
// import 'package:delivery_app_mvvm/data/network/api_service.dart'; // Your API service

class WalletRepository {
  // final ApiService _apiService;
  // WalletRepository(this._apiService);

  Future<Map<String, dynamic>> getWalletDetails() async {
    // final response = await _apiService.get('/wallet');
    // return response.data; // Assuming API service returns data map
    // Simulate API call
    await Future.delayed(Duration(seconds: 1));
    return {
      'balance': 350.50,
      'transactions': [
        {'id': 't1', 'description': 'Order #1', 'amount': 20.0, 'date': '2025-07-01T10:00:00Z', 'type': 'earning'},
      ],
      'bankAccounts': [
        {'id': 'b1', 'bankName': 'BANCOLOMBIA', 'accountNumberSuffix': '****1234', 'accountType': 'Ahorros', 'isPrimary': true},
      ]
    };
  }

  Future<void> requestWithdrawal(double amount, String bankAccountId) async {
    // await _apiService.post('/withdrawals/request', {'amount': amount, 'bankAccountId': bankAccountId});
    await Future.delayed(Duration(seconds: 1)); // Simulate
  }

  // Add methods for managing bank accounts
  // Future<void> addBankAccount(Map<String, dynamic> accountData) async { /* ... */ }
}