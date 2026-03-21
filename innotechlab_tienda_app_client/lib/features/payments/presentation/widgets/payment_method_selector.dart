import 'package:flutter/material.dart';
import '../../../../core/services/payments/payment_models.dart';

class PaymentMethodSelector extends StatelessWidget {
  final PaymentMethodType? selectedMethod;
  final Function(PaymentMethodType) onMethodSelected;
  final bool isProcessing;

  const PaymentMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onMethodSelected,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Método de pago',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildOption(
          context,
          method: PaymentMethodType.cash,
          title: 'Efectivo',
          subtitle: 'Pagar al recibir el pedido',
          icon: Icons.payments_outlined,
          color: Colors.green,
        ),
        const SizedBox(height: 12),
        _buildOption(
          context,
          method: PaymentMethodType.card,
          title: 'Tarjeta',
          subtitle: 'Visa, Mastercard, American Express',
          icon: Icons.credit_card,
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required PaymentMethodType method,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = selectedMethod == method;
    final theme = Theme.of(context);

    return Material(
      color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isProcessing ? null : () => onMethodSelected(method),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? color : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Radio<PaymentMethodType>(
                value: method,
                groupValue: selectedMethod,
                onChanged: isProcessing
                    ? null
                    : (value) {
                        if (value != null) onMethodSelected(value);
                      },
                activeColor: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
