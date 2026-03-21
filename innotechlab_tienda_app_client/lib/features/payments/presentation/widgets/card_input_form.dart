import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/payments/payment_models.dart';

class CardInputForm extends StatefulWidget {
  final Function(CardData) onSubmit;
  final bool isProcessing;

  const CardInputForm({
    super.key,
    required this.onSubmit,
    this.isProcessing = false,
  });

  @override
  State<CardInputForm> createState() => _CardInputFormState();
}

class _CardInputFormState extends State<CardInputForm> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _cardholderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  String? _detectedBrand;
  bool _showCvvHint = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardholderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _onCardNumberChanged(String value) {
    final cleaned = value.replaceAll(' ', '');
    if (cleaned.startsWith('4')) {
      setState(() => _detectedBrand = 'visa');
    } else if (cleaned.startsWith('5')) {
      setState(() => _detectedBrand = 'mastercard');
    } else if (cleaned.startsWith('34') || cleaned.startsWith('37')) {
      setState(() => _detectedBrand = 'amex');
    } else {
      setState(() => _detectedBrand = null);
    }

    if (value.length >= 19) {
      FocusScope.of(context).nextFocus();
    }
  }

  void _formatExpiry(String value) {
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length >= 2) {
      final month = cleaned.substring(0, 2);
      final year = cleaned.length > 2 ? cleaned.substring(2, 4) : '';
      final formatted = '$month/${year.isNotEmpty ? year : ''}';
      _expiryController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      final expiryParts = _expiryController.text.split('/');
      final cardData = CardData(
        cardNumber: _cardNumberController.text.replaceAll(' ', ''),
        cardholderName: _cardholderController.text.trim(),
        cvv: _cvvController.text,
        expiryMonth: expiryParts[0],
        expiryYear: expiryParts.length > 1 ? expiryParts[1] : '',
      );
      widget.onSubmit(cardData);
    }
  }

  String? _validateCardNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa el número de tarjeta';
    }
    final cleaned = value.replaceAll(' ', '');
    if (cleaned.length < 13 || cleaned.length > 19) {
      return 'Número de tarjeta inválido';
    }
    if (!_luhnCheck(cleaned)) {
      return 'Número de tarjeta inválido';
    }
    return null;
  }

  bool _luhnCheck(String number) {
    int sum = 0;
    bool alternate = false;
    for (int i = number.length - 1; i >= 0; i--) {
      int digit = int.parse(number[i]);
      if (alternate) {
        digit *= 2;
        if (digit > 9) digit = (digit % 10) + 1;
      }
      sum += digit;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  String? _validateExpiry(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa la fecha';
    }
    final parts = value.split('/');
    if (parts.length != 2) {
      return 'Formato inválido (MM/YY)';
    }
    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);
    if (month == null || month < 1 || month > 12) {
      return 'Mes inválido';
    }
    if (year == null) {
      return 'Año inválido';
    }
    return null;
  }

  String? _validateCvv(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa el CVV';
    }
    if (value.length < 3 || value.length > 4) {
      return 'CVV inválido';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCardNumberField(),
          const SizedBox(height: 16),
          _buildCardholderField(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildExpiryField()),
              const SizedBox(width: 16),
              Expanded(child: _buildCvvField()),
            ],
          ),
          const SizedBox(height: 24),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildCardNumberField() {
    return TextFormField(
      controller: _cardNumberController,
      decoration: InputDecoration(
        labelText: 'Número de tarjeta',
        hintText: '1234 5678 9012 3456',
        prefixIcon: const Icon(Icons.credit_card),
        suffixIcon: _detectedBrand != null
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: _buildCardBrandIcon(_detectedBrand!),
              )
            : null,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(19),
        _CardNumberFormatter(),
      ],
      validator: _validateCardNumber,
      onChanged: _onCardNumberChanged,
      enabled: !widget.isProcessing,
    );
  }

  Widget _buildCardholderField() {
    return TextFormField(
      controller: _cardholderController,
      decoration: const InputDecoration(
        labelText: 'Nombre en la tarjeta',
        hintText: 'Como aparece en la tarjeta',
        prefixIcon: Icon(Icons.person),
        border: OutlineInputBorder(),
      ),
      textCapitalization: TextCapitalization.characters,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Ingresa el nombre';
        }
        return null;
      },
      enabled: !widget.isProcessing,
    );
  }

  Widget _buildExpiryField() {
    return TextFormField(
      controller: _expiryController,
      decoration: const InputDecoration(
        labelText: 'MM/YY',
        hintText: '12/25',
        prefixIcon: Icon(Icons.calendar_today),
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(5),
      ],
      validator: _validateExpiry,
      onChanged: _formatExpiry,
      enabled: !widget.isProcessing,
    );
  }

  Widget _buildCvvField() {
    return MouseRegion(
      onEnter: (_) => setState(() => _showCvvHint = true),
      onExit: (_) => setState(() => _showCvvHint = false),
      child: TextFormField(
        controller: _cvvController,
        decoration: InputDecoration(
          labelText: 'CVV',
          hintText: '123',
          prefixIcon: const Icon(Icons.lock),
          suffixIcon: _showCvvHint
              ? Tooltip(
                  message: 'El CVV son los 3 o 4 dígitos detrás de tu tarjeta',
                  child: const Icon(Icons.help_outline, size: 20),
                )
              : null,
          border: const OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        obscureText: true,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(4),
        ],
        validator: _validateCvv,
        enabled: !widget.isProcessing,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: widget.isProcessing ? null : _onSubmit,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      child: widget.isProcessing
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text(
              'PAGAR',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }

  Widget _buildCardBrandIcon(String brand) {
    IconData icon;
    Color color;

    switch (brand) {
      case 'visa':
        icon = Icons.credit_card;
        color = Colors.blue;
        break;
      case 'mastercard':
        icon = Icons.credit_card;
        color = Colors.orange;
        break;
      case 'amex':
        icon = Icons.credit_card;
        color = Colors.green;
        break;
      default:
        icon = Icons.credit_card;
        color = Colors.grey;
    }

    return Icon(icon, color: color, size: 24);
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final formatted = text.replaceAllMapped(
      RegExp(r'.{1,4}'),
      (match) => '${match.group(0)} ',
    );
    return TextEditingValue(
      text: formatted.trim(),
      selection: TextSelection.collapsed(
        offset: formatted.trim().length.clamp(0, 23),
      ),
    );
  }
}
