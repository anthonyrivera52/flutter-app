import 'package:delivery_app_mvvm/domain/entities/bank_account.dart';
import 'package:delivery_app_mvvm/domain/entities/transaction.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Import your ViewModel and Models
import 'package:delivery_app_mvvm/viewmodel/wallet_view_model.dart'; // Your WalletViewModel

// Make sure your Transaction and BankAccount models are imported or defined
// If you moved them, update these imports
// import 'package:delivery_app_mvvm/domain/entities/transaction.dart';
// import 'package:delivery_app_mvvm/domain/entities/bank_account.dart';


class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Fetch initial wallet data when the screen loads
      Provider.of<WalletViewModel>(context, listen: false).fetchWalletData();
    });
  }

  Widget _buildBalanceCard(BuildContext context, double balance, WalletViewModel viewModel) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Saldo Disponible',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${balance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: balance > 0 && viewModel.bankAccounts.isNotEmpty
                      ? () => _showWithdrawalDialog(context, balance, viewModel)
                      : null, // Disable button if balance is zero or no bank accounts
                  icon: const Icon(Icons.account_balance_wallet, color: Colors.white),
                  label: const Text(
                    'Retirar Fondos',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            const Divider(),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // You'd fetch these from the ViewModel as well if your backend provides them
                _buildSmallInfoCard('Pendiente', '\$0.00'),
                _buildSmallInfoCard('Último Retiro', '\$150.00'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallInfoCard(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    IconData icon;
    Color iconColor;
    String sign;

    switch (transaction.type) {
      case TransactionType.earning:
        icon = Icons.add_circle_outline;
        iconColor = Colors.green;
        sign = '+';
        break;
      case TransactionType.payout:
        icon = Icons.arrow_upward; // Or Icons.send for funds leaving
        iconColor = Colors.blue;
        sign = '-';
        break;
      case TransactionType.deduction:
        icon = Icons.remove_circle_outline;
        iconColor = Colors.red;
        sign = '-';
        break;
      case TransactionType.bonus:
        icon = Icons.star;
        iconColor = Colors.orange;
        sign = '+';
        break;
      default:
        icon = Icons.info_outline;
        iconColor = Colors.grey;
        sign = '';
        break;
    }


    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(transaction.description),
        subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(transaction.date)),
        trailing: Text(
          '$sign\$${transaction.amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: iconColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  void _showWithdrawalDialog(BuildContext context, double currentBalance, WalletViewModel viewModel) {
    final TextEditingController amountController = TextEditingController();
    BankAccount? selectedAccount = viewModel.bankAccounts.isNotEmpty ? viewModel.bankAccounts.firstWhere((acc) => acc.isPrimary, orElse: () => viewModel.bankAccounts.first) : null;


    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder( // Use StatefulBuilder to update dialog state
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: const Text('Retirar Fondos'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tu saldo actual es: \$${currentBalance.toStringAsFixed(2)}'),
                    const SizedBox(height: 10),
                    const Text('¿A qué cuenta bancaria deseas consignar?', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    if (viewModel.bankAccounts.isEmpty)
                      const Text('No tienes cuentas bancarias registradas. Por favor, agrega una en "Cuentas Bancarias".', style: TextStyle(color: Colors.red))
                    else
                      DropdownButtonFormField<BankAccount>(
                        value: selectedAccount,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          labelText: 'Seleccionar Cuenta',
                        ),
                        items: viewModel.bankAccounts.map((account) {
                          return DropdownMenuItem<BankAccount>(
                            value: account,
                            child: Text('${account.bankName} - ${account.accountNumberSuffix} (${account.accountType})'),
                          );
                        }).toList(),
                        onChanged: (BankAccount? newValue) {
                          setStateInDialog(() {
                            selectedAccount = newValue;
                          });
                        },
                        validator: (value) => value == null ? 'Por favor, selecciona una cuenta.' : null,
                      ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Monto a retirar',
                        hintText: 'Ej: 50.00',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixText: '\$',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa un monto.';
                        }
                        final double? amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return 'Monto inválido.';
                        }
                        if (amount > currentBalance) {
                          return 'No puedes retirar más de tu saldo disponible.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: selectedAccount != null && double.tryParse(amountController.text) != null && double.tryParse(amountController.text)! > 0 && double.tryParse(amountController.text)! <= currentBalance
                      ? () async {
                          final double amountToWithdraw = double.parse(amountController.text);
                          final String? accountId = selectedAccount?.id;

                          if (accountId != null) {
                            Navigator.of(dialogContext).pop(); // Dismiss dialog first
                            bool success = await viewModel.requestWithdrawal(amountToWithdraw, accountId);
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Solicitud de retiro enviada, ¡gracias!'), backgroundColor: Colors.green),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(viewModel.errorMessage ?? 'Error al solicitar retiro.'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        }
                      : null, // Disable button if conditions not met
                  child: const Text('Confirmar Retiro'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletViewModel = Provider.of<WalletViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Billetera'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: walletViewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : walletViewModel.errorMessage != null
              ? Center(
                  child: Text(
                    'Error: ${walletViewModel.errorMessage}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                )
              : RefreshIndicator( // Allow pull-to-refresh
                  onRefresh: walletViewModel.fetchWalletData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(), // Always allow scroll for RefreshIndicator
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBalanceCard(context, walletViewModel.currentBalance, walletViewModel),

                        const Text(
                          'Actividad Reciente',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 15),

                        if (walletViewModel.transactions.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text('No hay transacciones recientes.'),
                            ),
                          )
                        else
                          // Sort transactions by date descending (most recent first)
                          ...(
                            (walletViewModel.transactions.toList()..sort((a, b) => b.date.compareTo(a.date)))
                              .map((tx) => _buildTransactionItem(tx))
                              .toList()
                          ),

                        const SizedBox(height: 20),

                        // Option to manage bank accounts
                        ListTile(
                          leading: const Icon(Icons.account_balance),
                          title: const Text('Cuentas Bancarias'),
                          subtitle: Text(
                            walletViewModel.bankAccounts.isEmpty
                                ? 'No tienes cuentas bancarias registradas.'
                                : 'Gestiona tus ${walletViewModel.bankAccounts.length} métodos de consignación',
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            // TODO: Navigate to a separate screen for managing bank accounts
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Navegar a Gestión de Cuentas Bancarias')));
                          },
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}