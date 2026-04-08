import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'payment_exceptions.dart';

final boldPaymentServiceProvider = Provider<BoldPaymentService>((ref) {
  return BoldPaymentService();
});

class BoldBuyerData {
  final String name;
  final String email;
  final String? phone;
  final String? documentType;
  final String? documentNumber;

  const BoldBuyerData({
    required this.name,
    required this.email,
    this.phone,
    this.documentType,
    this.documentNumber,
  });
}

class BoldCheckoutData {
  final String apiKey;
  final String orderId;
  final int amount;
  final String currency;
  final String integritySignature;
  final String redirectionUrl;
  final String description;
  final BoldBuyerData? buyer;

  const BoldCheckoutData({
    required this.apiKey,
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.integritySignature,
    required this.redirectionUrl,
    required this.description,
    this.buyer,
  });
}

class BoldPaymentService {
  String get _supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  String get _supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  String get _apiKey => dotenv.env['BOLD_API_KEY'] ?? '';
  String get _redirectionUrl =>
      '$_supabaseUrl/functions/v1/bold-payment-callback';

  Future<BoldCheckoutData> createCheckoutData({
    required String orderId,
    required int amount,
    String currency = 'COP',
    String? description,
    BoldBuyerData? buyer,
  }) async {
    if (_apiKey.isEmpty) {
      throw PaymentValidationException('BOLD_API_KEY no configurada');
    }

    try {
      final Map<String, dynamic> requestBody = {
        'orderId': orderId,
        'amount': amount,
        'currency': currency,
      };

      if (buyer != null) {
        requestBody['buyer'] = {
          'name': buyer.name,
          'email': buyer.email,
          if (buyer.phone != null) 'phone': buyer.phone,
          if (buyer.documentType != null) 'documentType': buyer.documentType,
          if (buyer.documentNumber != null)
            'documentNumber': buyer.documentNumber,
        };
      }

      final response = await http.post(
        Uri.parse('$_supabaseUrl/functions/v1/bold-generate-hash'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_supabaseAnonKey',
        },
        body: jsonEncode(requestBody),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200 || data['hash'] == null) {
        throw PaymentProcessingException(
          data['error'] as String? ?? 'Error al generar hash de integridad',
        );
      }

      return BoldCheckoutData(
        apiKey: _apiKey,
        orderId: orderId,
        amount: amount,
        currency: currency,
        integritySignature: data['hash'] as String,
        redirectionUrl: _redirectionUrl,
        description: description ?? 'Pedido #$orderId',
        buyer: buyer,
      );
    } on http.ClientException catch (e) {
      throw PaymentConnectionException('Error de conexión: ${e.message}');
    } catch (e) {
      if (e is PaymentException) rethrow;
      throw PaymentProcessingException(
        'Error inesperado al preparar pago Bold: $e',
      );
    }
  }
}
