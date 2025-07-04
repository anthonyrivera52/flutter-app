
// Define the Transaction and TransactionType in your domain/entities folder
// For now, let's include them here to show the ViewModel structure
enum TransactionType { earning, payout, deduction, bonus }

class Transaction {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final TransactionType type;

  Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
  });

  // Factory constructor for parsing from JSON (assuming API returns a map)
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      type: TransactionType.values.firstWhere(
          (e) => e.toString().split('.').last == json['type']), // Convert string to enum
    );
  }
}