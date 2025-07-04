
// And a simple BankAccount model
class BankAccount {
  final String id;
  final String bankName;
  final String accountNumberSuffix; // e.g., ****1234
  final String accountType; // e.g., "Ahorros", "Corriente"
  final bool isPrimary;

  BankAccount({
    required this.id,
    required this.bankName,
    required this.accountNumberSuffix,
    required this.accountType,
    this.isPrimary = false,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'] as String,
      bankName: json['bankName'] as String,
      accountNumberSuffix: json['accountNumberSuffix'] as String,
      accountType: json['accountType'] as String,
      isPrimary: json['isPrimary'] as bool? ?? false,
    );
  }
}