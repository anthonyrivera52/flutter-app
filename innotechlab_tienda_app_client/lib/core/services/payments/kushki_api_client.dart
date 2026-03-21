import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'payment_models.dart';
import 'payment_exceptions.dart';

class KushkiApiClient {
  final String baseUrl;
  final String publicMerchantId;
  final bool testEnvironment;

  KushkiApiClient({String? publicMerchantId, String? environment})
    : publicMerchantId =
          publicMerchantId ?? dotenv.env['KUSHKI_PUBLIC_KEY'] ?? '',
      testEnvironment = environment != 'production',
      baseUrl = (environment == 'production'
          ? 'https://api.kushkipagos.com'
          : 'https://api-uat.kushkipagos.com');

  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  Future<KushkiTokenResult> tokenizeCard({
    required CardData card,
    required double amount,
    required String currency,
  }) async {
    try {
      final cardNumberClean = card.cardNumber.replaceAll(' ', '');

      final requestBody = {
        'card': {
          'name': card.cardholderName,
          'number': cardNumberClean,
          'cvv': card.cvv,
          'expiryMonth': card.expiryMonth,
          'expiryYear': card.expiryYear,
        },
        'amount': {'subtotalIva': 0, 'iva': 0, 'subtotalIva0': amount},
        'currency': currency,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/card/v1/tokens'),
        headers: _headers,
        body: jsonEncode(requestBody),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['token'] != null) {
        return KushkiTokenResult.success(
          token: data['token'] as String,
          cardLastFour: card.lastFour,
          cardBrand: card.brand,
        );
      } else {
        return KushkiTokenResult.failed(
          error: data['message'] as String? ?? 'Error al tokenizar tarjeta',
          errorCode: data['code'] as String?,
        );
      }
    } on http.ClientException catch (e) {
      throw PaymentConnectionException('Error de conexión: ${e.message}');
    } catch (e) {
      if (e is PaymentException) rethrow;
      throw PaymentProcessingException('Error inesperado al tokenizar: $e');
    }
  }

  Future<PaymentResult> processPayment({
    required String saleId,
    required PaymentMethodType method,
    String? cardToken,
    String? cardLastFour,
    String? cardBrand,
  }) async {
    try {
      final body = <String, dynamic>{
        'saleId': saleId,
        'paymentMethod': method == PaymentMethodType.card ? 'card' : 'cash',
      };

      if (method == PaymentMethodType.card && cardToken != null) {
        body['cardToken'] = cardToken;
        body['cardLastFour'] = cardLastFour;
        body['cardBrand'] = cardBrand;
      }

      final response = await http.post(
        Uri.parse(
          '${dotenv.env['SUPABASE_URL']}/functions/v1/kushki-process-payment',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${dotenv.env['SUPABASE_ANON_KEY']}',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return PaymentResult.fromJson(data);
      } else {
        return PaymentResult.failed(
          data['error'] as String? ?? 'Error al procesar pago',
          errorCode: data['errorCode'] as String?,
        );
      }
    } on http.ClientException catch (e) {
      throw PaymentConnectionException('Error de conexión: ${e.message}');
    } catch (e) {
      if (e is PaymentException) rethrow;
      throw PaymentProcessingException('Error inesperado al procesar: $e');
    }
  }

  Future<RefundResult> refundPayment({
    required String transactionId,
    double? amount,
    String? reason,
  }) async {
    try {
      final body = <String, dynamic>{'transactionId': transactionId};

      if (amount != null) {
        body['amount'] = amount;
      }
      if (reason != null) {
        body['reason'] = reason;
      }

      final response = await http.post(
        Uri.parse('${dotenv.env['SUPABASE_URL']}/functions/v1/kushki-refund'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${dotenv.env['SUPABASE_ANON_KEY']}',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return RefundResult.fromJson(data);
      } else {
        return RefundResult(
          success: false,
          error: data['error'] as String? ?? 'Error al procesar reembolso',
        );
      }
    } on http.ClientException catch (e) {
      throw PaymentConnectionException('Error de conexión: ${e.message}');
    } catch (e) {
      if (e is PaymentException) rethrow;
      throw PaymentProcessingException('Error inesperado al reembolsar: $e');
    }
  }

  bool validateCardNumber(String number) {
    final cleanNumber = number.replaceAll(' ', '');
    if (cleanNumber.length < 13 || cleanNumber.length > 19) return false;
    return _luhnCheck(cleanNumber);
  }

  bool _luhnCheck(String number) {
    int sum = 0;
    bool alternate = false;

    for (int i = number.length - 1; i >= 0; i--) {
      int digit = int.parse(number[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit = (digit % 10) + 1;
        }
      }

      sum += digit;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }

  String? detectCardBrand(String number) {
    final cleanNumber = number.replaceAll(' ', '');

    if (cleanNumber.startsWith('4')) return 'visa';
    if (cleanNumber.startsWith('5') && cleanNumber.length > 1) {
      final secondDigit = int.tryParse(cleanNumber[1]) ?? 0;
      if (secondDigit >= 1 && secondDigit <= 5) return 'mastercard';
    }
    if (cleanNumber.startsWith('34') || cleanNumber.startsWith('37')) {
      return 'amex';
    }
    if (cleanNumber.startsWith('6011') || cleanNumber.startsWith('65')) {
      return 'discover';
    }
    if (cleanNumber.startsWith('36') || cleanNumber.startsWith('38')) {
      return 'diners';
    }
    if (cleanNumber.startsWith('35')) return 'jcb';

    return null;
  }
}

class KushkiTokenResult {
  final bool success;
  final String? token;
  final String? cardLastFour;
  final String? cardBrand;
  final String? error;
  final String? errorCode;

  const KushkiTokenResult._({
    required this.success,
    this.token,
    this.cardLastFour,
    this.cardBrand,
    this.error,
    this.errorCode,
  });

  factory KushkiTokenResult.success({
    required String token,
    String? cardLastFour,
    String? cardBrand,
  }) {
    return KushkiTokenResult._(
      success: true,
      token: token,
      cardLastFour: cardLastFour,
      cardBrand: cardBrand,
    );
  }

  factory KushkiTokenResult.failed({required String error, String? errorCode}) {
    return KushkiTokenResult._(
      success: false,
      error: error,
      errorCode: errorCode,
    );
  }
}
