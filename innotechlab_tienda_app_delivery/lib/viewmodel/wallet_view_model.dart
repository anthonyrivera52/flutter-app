import 'package:delivery_app_mvvm/domain/entities/bank_account.dart';
import 'package:delivery_app_mvvm/domain/entities/transaction.dart';
import 'package:flutter/foundation.dart'; // For ChangeNotifier
// import 'package:delivery_app_mvvm/data/repositories/wallet_repository.dart'; // You'll create this
// import 'package:delivery_app_mvvm/domain/entities/transaction.dart'; // Your Transaction model
// import 'package:delivery_app_mvvm/domain/entities/bank_account.dart'; // You'll create this


class WalletViewModel extends ChangeNotifier {
  // final WalletRepository _walletRepository; // Uncomment when you have a repository

  // Constructor (inject repository if using one)
  // WalletViewModel(this._walletRepository);

  double _currentBalance = 0.0;
  List<Transaction> _transactions = [];
  List<BankAccount> _bankAccounts = [];
  bool _isLoading = false;
  String? _errorMessage;

  double get currentBalance => _currentBalance;
  List<Transaction> get transactions => _transactions;
  List<BankAccount> get bankAccounts => _bankAccounts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Initial data fetch
  Future<void> fetchWalletData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // Notify listeners that loading has started

    try {
      // TODO: Replace with actual API calls via WalletRepository
      // Example: final Map<String, dynamic> data = await _walletRepository.getWalletDetails();
      // _currentBalance = data['balance'];
      // _transactions = (data['transactions'] as List).map((t) => Transaction.fromJson(t)).toList();
      // _bankAccounts = (data['bankAccounts'] as List).map((b) => BankAccount.fromJson(b)).toList();

      // --- Simulating API call with dummy data ---
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      _currentBalance = 350.50;
      _transactions = [
        Transaction(id: 'tx1', description: 'Pago pedido #123', amount: 25.50, date: DateTime.now().subtract(const Duration(hours: 2)), type: TransactionType.earning),
        Transaction(id: 'tx2', description: 'Retiro a cuenta bancaria', amount: 150.00, date: DateTime.now().subtract(const Duration(days: 1)), type: TransactionType.payout),
        Transaction(id: 'tx3', description: 'Pago pedido #12346', amount: 30.20, date: DateTime.now().subtract(const Duration(days: 1, hours: 5)), type: TransactionType.earning),
        Transaction(id: 'tx4', description: 'Deducción por comisión', amount: 5.00, date: DateTime.now().subtract(const Duration(days: 2)), type: TransactionType.deduction),
        Transaction(id: 'tx5', description: 'Bonus por rendimiento', amount: 10.00, date: DateTime.now().subtract(const Duration(days: 3)), type: TransactionType.bonus),
      ];
      _bankAccounts = [
        BankAccount(id: 'ba1', bankName: 'BANCOLOMBIA', accountNumberSuffix: '****1234', accountType: 'Ahorros', isPrimary: true),
        BankAccount(id: 'ba2', bankName: 'DAVIVIENDA', accountNumberSuffix: '****5678', accountType: 'Corriente'),
      ];
      // --- End Dummy Data ---

      _errorMessage = null; // Clear any previous errors
    } catch (e) {
      _errorMessage = 'Error al cargar los datos de la billetera: ${e.toString()}';
      debugPrint('WalletViewModel fetch error: $e');
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify listeners that loading has finished
    }
  }

  // Request a withdrawal
  Future<bool> requestWithdrawal(double amount, String bankAccountId) async {
    if (amount <= 0 || amount > _currentBalance) {
      _errorMessage = 'Monto de retiro inválido.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // TODO: Replace with actual API call to initiate withdrawal
      // Example: await _walletRepository.requestWithdrawal(amount, bankAccountId);

      // --- Simulate successful withdrawal ---
      await Future.delayed(const Duration(seconds: 2));
      _currentBalance -= amount; // Update local balance
      _transactions.insert(0, Transaction( // Add new transaction at the top
        id: DateTime.now().microsecondsSinceEpoch.toString(), // Unique ID
        description: 'Solicitud de retiro a ${bankAccounts.firstWhere((acc) => acc.id == bankAccountId).bankName}',
        amount: amount,
        date: DateTime.now(),
        type: TransactionType.payout,
      ));
      _errorMessage = null;
      return true; // Indicate success
    } catch (e) {
      _errorMessage = 'Error al procesar el retiro: ${e.toString()}';
      debugPrint('WalletViewModel withdrawal error: $e');
      return false; // Indicate failure
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Future<void> addBankAccount(BankAccount newAccount) async { /* ... */ }
  // Future<void> removeBankAccount(String accountId) async { /* ... */ }
  // Future<void> setPrimaryBankAccount(String accountId) async { /* ... */ }
}